//
//  DBSQLiteConnection.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#define LOG_QUERIES NO

#import "DBSQLiteConnection.h"
#import "../Queries/DBQuery.h"
#import "../Debug.h"
#import "../Utilities/ISO8601DateFormatter.h"
#import <unistd.h>
#import <sqlite3.h>
#import <dispatch/dispatch.h>

/*! @cond IGNORE */
@interface DBSQLiteConnection () {  
    sqlite3 *_connection;
    NSMutableDictionary *_cachedStatements;
    NSMutableArray *_savePointStack;
}
- (sqlite3_stmt *)prepareQuerySQL:(NSString *)query
                             tail:(NSString **)outTail
                            error:(NSError **)outError;
- (void)finalizeQuery:(sqlite3_stmt *)query;
- (NSArray *)columnsForQuery:(sqlite3_stmt *)query;
- (id)valueForColumn:(unsigned int)colIndex query:(sqlite3_stmt *)query;
@end
/*! @endcond */

#pragma mark -

@implementation DBSQLiteConnection
+ (void)load
{
    @autoreleasepool {
        [DBConnection registerConnectionClass:self];
    }
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
    _path = URL ? URL.path : @":memory:";
    _cachedStatements = [NSMutableDictionary new];

    int sqliteError = 0;
    int flags = SQLITE_OPEN_READWRITE;
    if([URL.query rangeOfString:@"create=yes"].location != NSNotFound)
        flags |= SQLITE_OPEN_CREATE;
    
    sqliteError = sqlite3_open_v2([_path UTF8String], &_connection, flags, NULL);
    if(sqliteError != SQLITE_OK) {
        const char *errStr = sqlite3_errmsg(_connection);
        if(err != NULL) {
            *err = [NSError errorWithDomain:@"database.sqlite.openerror"
                                       code:DBSQLiteDatabaseNotFoundErrorCode
                                   userInfo:@{NSLocalizedDescriptionKey: @(errStr),
                         NSFilePathErrorKey:_path}];
        }
        return nil;
    }

    [self executeSQL:@"PRAGMA foreign_keys = ON" substitutions:nil error:NULL];

    return self;
}

#pragma mark -
#pragma mark SQL Executing
- (NSArray *)executeSQL:(NSString *)sql substitutions:(id)substitutions error:(NSError **)outErr
{
    static dispatch_once_t onceToken;
    static NSDateFormatter *dateFormatter;
    dispatch_once(&onceToken, ^{
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    });
    
    BOOL isDict = [substitutions isKindOfClass:[NSDictionary class]] ||
    [substitutions isKindOfClass:[NSMapTable class]];
    NSParameterAssert(!substitutions                                       ||
                      [substitutions isKindOfClass:[NSArray class]]        ||
                      [substitutions isKindOfClass:[NSPointerArray class]] ||
                      isDict);
    DBLog(@"Executing SQL: %@ subs: %@", sql, substitutions);
    // Prepare the query
    NSString *tail = nil;
    NSError *prepareErr;
    sqlite3_stmt *queryByteCode = [self prepareQuerySQL:sql
                                                   tail:&tail
                                                  error:&prepareErr];
    if(!queryByteCode) {
        if(outErr) *outErr = prepareErr;
        DBLog(@"Unable to prepare bytecode for SQLite query: '%@': %@", sql, [prepareErr localizedDescription]);
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
        else if([sub isKindOfClass:[NSString class]] || [[sub className] isEqualToString:@"NSCFString"])
            sqlite3_bind_text(queryByteCode, i+1, [sub UTF8String], -1, SQLITE_TRANSIENT);
        else if([sub isMemberOfClass:[NSData class]])
            sqlite3_bind_blob(queryByteCode, i+1, [sub bytes], (int)[sub length], SQLITE_STATIC); // Not sure if we should make this transient
        else if([sub isKindOfClass:[NSNumber class]]) {
            switch (*[sub objCType]) {
                case 'd':
                case 'f':
                    sqlite3_bind_double(queryByteCode, i+1, [sub doubleValue]);
                    break;
                case 'l':
                case 'L':
                case 'q':
                case 'Q':
                    sqlite3_bind_int64(queryByteCode, i+1, [sub longLongValue]);
                    break;
                default:
                    sqlite3_bind_int(queryByteCode, i+1, [sub intValue]);
                    break;
            }
        } else if([sub isMemberOfClass:[NSNull class]])
            sqlite3_bind_null(queryByteCode, i+1);
        else if([sub isKindOfClass:[NSDate class]])
            sqlite3_bind_text(queryByteCode, i+1, [[dateFormatter stringFromDate:sub] UTF8String], -1, SQLITE_TRANSIENT);
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

    if(tail)
        return [self executeSQL:tail
           substitutions:substitutions
                   error:outErr];
    else
        return rowArray;
}

- (NSDictionary *)columnsForTable:(NSString *)tableName
{
    NSArray *results = [self executeSQL:[NSString stringWithFormat:@"PRAGMA table_info(%@)", tableName]
                          substitutions:@[tableName]
                                  error:NULL];
    return [NSDictionary dictionaryWithObjects:[results valueForKey:@"type"]
                                       forKeys:[results valueForKey:@"name"]];
}

- (BOOL)closeConnection
{
    for(NSValue *query in _cachedStatements.allValues) {
        sqlite3_finalize([query pointerValue]);
    }
    [_cachedStatements removeAllObjects];

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
- (sqlite3_stmt *)prepareQuerySQL:(NSString *)query
                             tail:(NSString **)aoTail
                            error:(NSError **)outErr
{
    if(LOG_QUERIES)
        DBDebugLog(@"Preparing query: %@", query);

    // Prepare the query
    sqlite3_stmt *queryByteCode = [_cachedStatements[query] pointerValue];
    if(queryByteCode) {
        sqlite3_reset(queryByteCode);
        return queryByteCode;
    }

    const char *tailBuf = NULL;
    int err = sqlite3_prepare_v2(_connection,
                                 [query UTF8String],
                                 (int)[query lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                                 &queryByteCode,
                                 &tailBuf);
    if(err != SQLITE_OK || queryByteCode == NULL) {
        if(outErr)
            *outErr = [NSError errorWithDomain:DBConnectionErrorDomain
                                          code:0
                                      userInfo:@{ NSLocalizedDescriptionKey: @(sqlite3_errmsg(_connection)),
                       @"query": query }];
        return NULL;
    }

    NSString *tail = [[NSString stringWithUTF8String:tailBuf] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if([tail length] == 0)
        _cachedStatements[query] = [NSValue valueWithPointer:queryByteCode];
    else if(aoTail)
        *aoTail = tail;

    return queryByteCode;
}
- (void)finalizeQuery:(sqlite3_stmt *)query
{
    sqlite3_finalize(query);
}

// You have to step through the *query yourself,
- (id)valueForColumn:(unsigned int)colIndex query:(sqlite3_stmt *)query
{
    static dispatch_once_t onceToken;
    static ISO8601DateFormatter *dateFormatter;
    dispatch_once(&onceToken, ^{
        dateFormatter = [ISO8601DateFormatter new];
    });

    int columnType = sqlite3_column_type(query, colIndex);
    const char *declType, *strVal;
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
            declType = sqlite3_column_decltype(query, colIndex);
            strVal = (const char *)sqlite3_column_text(query, colIndex);
            if(declType && strncmp("date", declType, 4) == 0) {
                NSString *dateStr = [[NSString alloc] initWithBytesNoCopy:(void*)strVal
                                                                   length:strlen(strVal)
                                                                 encoding:NSUTF8StringEncoding
                                                             freeWhenDone:NO];
                return [dateFormatter dateFromString:dateStr];
            }
            return @(strVal);
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
    NSString * const savePointName = [[NSUUID UUID] UUIDString];
    char *errorMessage;
    int err = sqlite3_exec(_connection,
                           [[NSString stringWithFormat:@"SAVEPOINT '%@'", savePointName] UTF8String],
                           NULL, NULL, &errorMessage);
    if(err != SQLITE_OK)
    {
        [NSException raise:@"SQLite error"
                    format:@"Couldn't start transaction, Details: %@", @(errorMessage)];
        return NO;
    }
    
    if(!_savePointStack)
        _savePointStack = [NSMutableArray arrayWithObject:savePointName];
    else
        [_savePointStack addObject:savePointName];
    return YES;
}
- (BOOL)rollBack
{
    NSAssert([_savePointStack count] > 0, @"Not in a transaction");
    char *errorMessage;
    int err = sqlite3_exec(_connection,
                           [[NSString stringWithFormat:@"ROLLBACK TO SAVEPOINT '%@'", [_savePointStack lastObject]] UTF8String],
                           NULL, NULL, &errorMessage);
    if(err != SQLITE_OK)
    {
        [NSException raise:@"SQLite error"
                    format:@"Couldn't roll back transaction, Details: %@", @(errorMessage)];
        return NO;
    }
    [_savePointStack removeLastObject];
    return YES;
}
- (BOOL)endTransaction
{
    NSAssert([_savePointStack count] > 0, @"Not in a transaction");
    char *errorMessage;
    int err = sqlite3_exec(_connection,
                           [[NSString stringWithFormat:@"RELEASE SAVEPOINT '%@'", [_savePointStack lastObject]] UTF8String],
                           NULL, NULL, &errorMessage);
    if(err != SQLITE_OK)
    {
        [NSException raise:@"SQLite error" 
                    format:@"Couldn't end transaction, Details: %@", @(errorMessage)];
        return NO;
    }
    [_savePointStack removeLastObject];
    return YES;
}

#pragma mark -
#pragma mark Cleanup
- (void)dealloc
{
    [self closeConnection];
}
@end