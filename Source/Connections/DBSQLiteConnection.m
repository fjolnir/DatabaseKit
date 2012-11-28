//
//  DBSQLiteConnection.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#define LOG_QUERIES NO

#import "DBSQLiteConnection.h"
#import "DBQuery.h"
#import <unistd.h>
#import <sqlite3.h>

/*! @cond IGNORE */
@interface DBSQLiteConnection () {
    sqlite3 *_connection;
}
- (sqlite3_stmt *)prepareQuerySQL:(NSString *)query error:(NSError **)outError;
- (void)finalizeQuery:(sqlite3_stmt *)query;
- (NSArray *)columnsForQuery:(sqlite3_stmt *)query;
- (id)valueForColumn:(unsigned int)colIndex query:(sqlite3_stmt *)query;
@end
/*! @endcond */

#pragma mark -

@implementation DBSQLiteConnection
+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [DBConnection registerConnectionClass:self];
    });
}
+ (BOOL)canHandleURL:(NSURL *)URL
{
    return [[URL scheme] isEqualToString:@"sqlite"];
}

#pragma mark -
#pragma mark Initialization

- (id)initWithURL:(NSURL *)URL error:(NSError **)err;
{
    if(!(self = [super initWithURL:URL error:err]))
        return nil;
    
    _path = [[[URL absoluteString] substringFromIndex:9] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if(![[NSFileManager defaultManager] fileExistsAtPath:_path])
    {
        if(err != NULL) {
            *err = [NSError errorWithDomain:@"database.sqlite.filenotfound"
                                       code:DBSQLiteDatabaseNotFoundErrorCode
                                   userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"SQLite database not found", @""),
                         NSFilePathErrorKey: _path}];
        }
        return nil;
    }
    // Else
    int sqliteError = 0;
    sqliteError = sqlite3_open([_path UTF8String], &_connection);
    if(sqliteError != SQLITE_OK) {
        const char *errStr = sqlite3_errmsg(_connection);
        if(err != NULL) {
            *err = [NSError errorWithDomain:@"database.sqlite.openerror"
                                       code:DBSQLiteDatabaseNotFoundErrorCode
                                   userInfo:@{NSLocalizedDescriptionKey: @(errStr),
                         NSFilePathErrorKey:_path}];
        }
        return NULL;
    }
    return self;
}

#pragma mark -
#pragma mark SQL Executing
- (NSArray *)executeSQL:(NSString *)sql substitutions:(id)substitutions error:(NSError **)outErr
{
    BOOL isDict = [substitutions isKindOfClass:[NSDictionary class]] ||
    [substitutions isKindOfClass:[NSMapTable class]];
    NSParameterAssert(!substitutions                                       ||
                      [substitutions isKindOfClass:[NSArray class]]        ||
                      [substitutions isKindOfClass:[NSPointerArray class]] ||
                      isDict);
//    DBLog(@"Executing SQL: %@ subs: %@", sql, substitutions);
    // Prepare the query
    sqlite3_stmt *queryByteCode;
    queryByteCode = [self prepareQuerySQL:sql error:outErr];
    if(!queryByteCode) {
        DBLog(@"Unable to prepare bytecode for SQLite query: %@", sql);
        return nil;
    }
    NSArray *columnNames = [self columnsForQuery:queryByteCode];

    const char *keyCstring;
    NSString *key;
    id sub;
    for(int i = 0; i < sqlite3_bind_parameter_count(queryByteCode); ++i) {
        if(isDict) {
            keyCstring = sqlite3_bind_parameter_name(queryByteCode, i);
            if(!keyCstring)
                continue;
            key = [@(keyCstring) stringByReplacingOccurrencesOfString:@":" withString:@""];
            sub = substitutions[key];
        } else
            sub = substitutions[i];
        if(!sub)
            continue;
        if([sub isKindOfClass:[NSString class]] || [[sub className] isEqualToString:@"NSCFString"])
            sqlite3_bind_text(queryByteCode, i+1, [sub UTF8String], -1, SQLITE_TRANSIENT);
        else if([sub isMemberOfClass:[NSData class]])
            sqlite3_bind_blob(queryByteCode, i+1, [sub bytes], [sub length], SQLITE_STATIC); // Not sure if we should make this transient
        else if([sub isKindOfClass:[NSNumber class]])
            sqlite3_bind_double(queryByteCode, i+1, [sub doubleValue]);
        else if([sub isMemberOfClass:[NSNull class]])
            sqlite3_bind_null(queryByteCode, i+1);
        else
            [NSException raise:@"Unrecognized object type" format:@"DBKit doesn't know how to handle this type of object: %@ class: %@", sub, [sub className]];
    }

    NSMutableArray *rowArray = [NSMutableArray array];
    NSMutableDictionary *columns;
    int err = 0;
    while((err = sqlite3_step(queryByteCode)) != SQLITE_DONE)
    {
        if(err == SQLITE_BUSY)
        {
            DBDebugLog(@"busy!");
            usleep(100); // TODO: maybe *not* halt app execution if the database is busy?
        }
        else if(err == SQLITE_ERROR || err == SQLITE_MISUSE)
        {
            if(outErr)
                *outErr = [NSError errorWithDomain:DBConnectionErrorDomain
                                              code:0
                                          userInfo:@{ NSLocalizedDescriptionKey: @(sqlite3_errmsg(_connection)),
                           @"query": sql }];
            return nil;
        }
        else if(err == SQLITE_ROW)
        {
            // construct the dictionary for the row
            columns = [NSMutableDictionary dictionary];
            int i = 0;
            for(NSString *columnName in columnNames) {
                columns[columnName] = [self valueForColumn:i query:queryByteCode];
                ++i;
            }
            [rowArray addObject:columns];
        }
    }

    [self finalizeQuery:queryByteCode];
    return rowArray;
}

- (NSArray *)columnsForTable:(NSString *)tableName
{
    NSMutableString *query = [NSMutableString stringWithString:@"SELECT * FROM "];
    [query appendString:tableName];
    [query appendString:@" LIMIT 0"];
    sqlite3_stmt *queryByteCode = [self prepareQuerySQL:query error:nil];
    if(!queryByteCode)
        return nil;
    NSArray *columns = [self columnsForQuery:queryByteCode];
    [self finalizeQuery:queryByteCode];
    return columns;
}

- (BOOL)closeConnection
{
    BOOL ret = sqlite3_close(_connection) == SQLITE_OK;
    _connection = NULL;
    return ret;
}

#pragma mark Private
- (NSArray *)columnsForQuery:(sqlite3_stmt *)query
{
    int columnCount = sqlite3_column_count(query);
    if(columnCount <= 0)
        return nil;

    NSMutableArray *columnNames = [NSMutableArray array];
    for(int i = 0; i < columnCount; ++i)
    {
        const char *name;
        name = sqlite3_column_name(query, i);
        [columnNames addObject:@(name)];
    }
    return columnNames;
}
- (sqlite3_stmt *)prepareQuerySQL:(NSString *)query error:(NSError **)outErr
{
    if(LOG_QUERIES)
        DBDebugLog(@"Preparing query: %@", query);

    // Prepare the query
    sqlite3_stmt *queryByteCode;
    const char *tail;
    int err = sqlite3_prepare_v2(_connection,
                                 [query UTF8String],
                                 [query lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                                 &queryByteCode,
                                 &tail);
    if(err != SQLITE_OK || queryByteCode == NULL) {
        if(outErr)
            *outErr = [NSError errorWithDomain:DBConnectionErrorDomain
                                          code:0
                                      userInfo:@{ NSLocalizedDescriptionKey: @(sqlite3_errmsg(_connection)),
                       @"query": query }];
        return nil;
    }

    return queryByteCode;
}
- (void)finalizeQuery:(sqlite3_stmt *)query
{
    sqlite3_finalize(query);
}

// You have to step through the *query yourself,
- (id)valueForColumn:(unsigned int)colIndex query:(sqlite3_stmt *)query
{
    int columnType = sqlite3_column_type(query, colIndex);
    switch(columnType)
    {
        case SQLITE_INTEGER:
            return @(sqlite3_column_int(query, colIndex));
            break;
        case SQLITE_FLOAT:
            return @(sqlite3_column_double(query, colIndex));
            break;
        case SQLITE_BLOB:
            return [NSData dataWithBytes:sqlite3_column_blob(query, colIndex)
                                  length:sqlite3_column_bytes(query, colIndex)];
            break;
        case SQLITE_NULL:
            return [NSNull null];
            break;
        case SQLITE_TEXT:
            return @((const char *)sqlite3_column_text(query, colIndex));
            break;
        default:
            // It really shouldn't ever come to this.
            break;
    }
    return nil;
}

#pragma mark -
#pragma mark Transactions
- (BOOL)beginTransaction
{
    char *errorMessage;
    int err = sqlite3_exec(_connection, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
    if(err != SQLITE_OK)
    {
        [NSException raise:@"SQLite error"
                    format:@"Couldn't start transaction, Details: %@", @(errorMessage)];
        return NO;
    }
    return YES;
}
- (BOOL)rollBack
{
    char *errorMessage;
    int err = sqlite3_exec(_connection, "ROLLBACK", NULL, NULL, &errorMessage);
    if(err != SQLITE_OK)
    {
        [NSException raise:@"SQLite error"
                    format:@"Couldn't roll back transaction, Details: %@", @(errorMessage)];
        return NO;
    }
    return YES;
}
- (BOOL)endTransaction
{
    char *errorMessage;
    int err = sqlite3_exec(_connection, "END TRANSACTION", NULL, NULL, &errorMessage);
    if(err != SQLITE_OK)
    {
        [NSException raise:@"SQLite error" 
                    format:@"Couldn't end transaction, Details: %@", @(errorMessage)];
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark Cleanup
- (void)dealloc
{
    [self closeConnection];
}
@end