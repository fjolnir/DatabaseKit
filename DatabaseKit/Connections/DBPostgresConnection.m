//
//  DBPostgresConnection.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#define LOG_QUERIES NO

#import "DBPostgresConnection.h"
#import "../DBQuery.h"
#import "../Debug.h"
#import <unistd.h>
#import <dispatch/dispatch.h>
// For some reason, on linux (Debian at least) there's a postgresql/ prefix
#ifdef __APPLE__
#import <libpq-fe.h>
#else
#import <postgresql/libpq-fe.h>
#endif

#ifndef INT8OID
    #define INVALID_OID     (-1)
    #define INT8OID         20
    #define INT2OID         21
    #define INT4OID         23
    #define	BOOLOID         16
    #define FLOAT4OID       700
    #define FLOAT8OID       701
    #define VARCHAROID      1043
    #define	TEXTOID         25
    #define DATEOID         1082
    #define TIMEOID         1083
    #define TIMESTAMPOID    1114
    #define TIMESTAMPTZOID  1184
    #define BYTEAOID        17
#endif

/*! @cond IGNORE */
static NSRange rangeOfParameterToken(NSString *param, NSString *query);
static NSString *NSDateToPostgresTimestamp(NSDate *date);
static NSDate *NSDateFromPostgresTimestamp(NSString *timestamp);

@interface DBPostgresConnection () {
    PGconn *_connection;
}
- (id)valueForRow:(unsigned int)rowIndex column:(unsigned int)colIndex result:(PGresult *)result;
@end
/*! @endcond */

#pragma mark -

@implementation DBPostgresConnection
+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [DBConnection registerConnectionClass:self];
    });
}
+ (BOOL)canHandleURL:(NSURL *)URL
{
    return [[URL scheme] isEqualToString:@"postgres"];
}

+ (NSString *)postgresConnectionStringFromURL:(NSURL *)url
{
    NSMutableString *connectionString = [NSMutableString stringWithString:@""];
    if([url host])
        [connectionString appendFormat:@"host='%@' ", [url host]];
    else
        return nil;
    if([url port])
        [connectionString appendFormat:@"port='%@' ", [url port]];
    if([url user])
        [connectionString appendFormat:@"user='%@' ", [url user]];
    if([url password])
        [connectionString appendFormat:@"password='%@' ", [url password]];
    NSString *dbName = [[url lastPathComponent] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if([dbName length] > 0 && ![dbName isEqual:@"/"])
        [connectionString appendFormat:@"dbname='%@' ", dbName];
    else
        return nil; // No database, no dice

    return connectionString;
}

#pragma mark -
#pragma mark Initialization

- (id)initWithURL:(NSURL *)URL error:(NSError **)err;
{
    if(!(self = [super initWithURL:URL error:err]))
        return nil;
    NSString *connInfo = [[self class] postgresConnectionStringFromURL:URL];
    NSAssert1(connInfo, @"Invalid PostgreSQL URL: %@", URL);
    _connection = PQconnectdb([connInfo UTF8String]);
    if(PQstatus(_connection) != CONNECTION_OK) {
        DBLog(@"Unable to connect to %@: %@", URL, @(PQerrorMessage(_connection)));
        if(err) {
            *err = [NSError errorWithDomain:DBConnectionErrorDomain
                                       code:DBPostgresConnectionFailed
                                   userInfo:@{ NSLocalizedDescriptionKey: @(PQerrorMessage(_connection)),
                                                           NSURLErrorKey: URL }];
        }
        return nil;
    }
    return self;
}
- (void)dealloc
{
    [self closeConnection];
}
- (BOOL)closeConnection
{
    if(!_connection)
        return NO;
    PQfinish(_connection), _connection = NULL;
    return YES;
}

#pragma mark -
#pragma mark SQL Execution

- (NSArray *)executeSQL:(NSString *)sql substitutions:(id)substitutions error:(NSError **)outErr
{
    DBLog(@"%@ -- %@", sql, substitutions);
    BOOL isDict = [substitutions isKindOfClass:[NSDictionary class]] ||
                  [substitutions isKindOfClass:[NSMapTable class]];
    NSParameterAssert(!substitutions                                       ||
                      [substitutions isKindOfClass:[NSArray class]]        ||
                      [substitutions isKindOfClass:[NSPointerArray class]] ||
                      isDict);
    //DBDebugLog(@"Executing SQL: %@ subs: %@", sql, substitutions);
    // Prepare the query

    NSUInteger paramCount = [substitutions count];
    const char *paramValues[paramCount];
    int paramLengths[paramCount];
    int paramFormats[paramCount]; // 0 = text, 1 = binary

    NSString *key;
    int i = 0;
    for(__strong id sub in substitutions) {
        if(isDict) {
            key = sub;
            sub = substitutions[key];
            // Unfortunately Postgres doesn't support `:<param>` style named parameters => we need to manually anonymize
            NSString *paramToken = [@":" stringByAppendingString:key];
            NSRange tokenRange = rangeOfParameterToken(paramToken, sql);
            if(tokenRange.location == NSNotFound)
                continue;
            sql = [sql stringByReplacingOccurrencesOfString:paramToken
                                                 withString:[@"$" stringByAppendingFormat:@"%d", i]];
        }

        if([sub isKindOfClass:[NSString class]] || [[sub className] isEqualToString:@"NSCFString"]) {
            paramValues[i]  = [sub UTF8String];
            paramLengths[i] = [sub length];
            paramFormats[i] = 0;
        } else if([sub isKindOfClass:[NSNumber class]] || [sub isKindOfClass:NSClassFromString(@"TQNumber")]) {
            NSString *str;
            switch (*[sub objCType]) {
                case 'd':
                case 'f':
                    str = [NSString stringWithFormat:@"%f", [sub doubleValue]];
                    break;
                case 'l':
                case 'L':
                    str = [NSString stringWithFormat:@"%ld", [sub longValue]];
                    break;
                case 'q':
                case 'Q':
                    str = [NSString stringWithFormat:@"%lld", [sub longLongValue]];
                    break;
                case 'B': // C++/C99 bool
                case 'c': // ObjC BOOL
                    str = [NSString stringWithFormat:@"%d", [sub intValue]];
                    break;
                default:
                    str = [NSString stringWithFormat:@"%ld", [sub longValue]];
                    break;
            }
            paramValues[i]  = [str UTF8String];
            paramLengths[i] = [str length];
            paramFormats[i] = 0;
        } else if([sub isKindOfClass:[NSData class]]) {
            paramValues[i]  = [sub bytes];
            paramLengths[i] = [sub length];
            paramFormats[i] = 1;
        } else if([sub isKindOfClass:[NSDate class]]) {
            NSString *timestamp = NSDateToPostgresTimestamp(sub);
            paramValues[i]  = [timestamp UTF8String];
            paramLengths[i] = [timestamp length];
            paramFormats[i] = 0;
        } else if(!sub || [sub isMemberOfClass:[NSNull class]]) {
            paramValues[i]  = NULL;
            paramLengths[i] = 0;
            paramFormats[i] = 0;
        } else
            [NSException raise:@"Unrecognized object type"
                        format:@"DatabaseKit doesn't know how to handle this type of object: %@ class: %@", sub, [sub className]];
        ++i;
    }

    PGresult *result = PQexecParams(_connection, [sql UTF8String], paramCount, NULL, paramValues, paramLengths, paramFormats, 0);
    switch (PQresultStatus(result)) {
        case PGRES_BAD_RESPONSE:
        case PGRES_FATAL_ERROR:
            DBDebugLog(@"Query error: %@", [NSString stringWithUTF8String:PQresultErrorMessage(result)]);
            if(outErr)
                *outErr = [[NSError alloc] initWithDomain:DBConnectionErrorDomain
                                                     code:DBPostgreQueryFailed
                                                 userInfo:@{ NSLocalizedDescriptionKey: @(PQresultErrorMessage(result)) }];
            return nil;
        default:
            break;
    }
    int rowCount = PQntuples(result);
    NSArray *columnNames = [self columnsForResult:result];
    NSMutableArray *rowArray = [NSMutableArray array];
    NSMutableDictionary *columns;
    for(int i = 0; i < rowCount; ++i) {
        // construct the dictionary for the row
        columns = [NSMutableDictionary dictionary];
        int j = 0;
        for(NSString *columnName in columnNames) {
            columns[columnName] = [self valueForRow:i column:j result:result];
            ++j;
        }
        [rowArray addObject:columns];
    }
    PQclear(result);
    return rowArray;
}

- (NSArray *)columnsForTable:(NSString *)tableName
{
    NSMutableString *query = [NSMutableString stringWithString:@"SELECT * FROM "];
    [query appendString:tableName];
    [query appendString:@" LIMIT 0"];
    PGresult *result = PQexec(_connection, [query UTF8String]);
    switch (PQresultStatus(result)) {
        case PGRES_BAD_RESPONSE:
        case PGRES_FATAL_ERROR:
            return nil;
        default: break;
    }
    NSArray *columns = [self columnsForResult:result];
    PQclear(result);
    return columns;
}


#pragma mark Private
- (NSArray *)columnsForResult:(PGresult *)result
{
    int colCount = PQnfields(result);
    if(colCount <= 0)
        return nil;

    NSMutableArray *columnNames = [NSMutableArray array];
    for(int i = 0; i < colCount; ++i) {
        [columnNames addObject:@(PQfname(result, i))];
    }
    return columnNames;
}


// You have to step through the *query yourself,
- (id)valueForRow:(unsigned int)rowIndex column:(unsigned int)colIndex result:(PGresult *)result
{
    const char *bytes = PQgetvalue(result, rowIndex, colIndex);
    if(!bytes)
        return [NSNull null];
    
    NSUInteger length = PQgetlength(result, rowIndex, colIndex);
    switch(PQftype(result, colIndex))
    {
        case INT2OID:
             return @(atoi(bytes));
        case INT4OID:
            return @(strtoul(bytes, (char **)NULL, 10));
        case INT8OID:
            return @(strtoull(bytes, (char **)NULL, 10));
        case FLOAT4OID:
        case FLOAT8OID:
            return @(atof(bytes));
            break;
        case DATEOID:
        case TIMEOID:
        case TIMESTAMPOID:
        case TIMESTAMPTZOID:
            return NSDateFromPostgresTimestamp(@(bytes));
        case BYTEAOID: {
            const unsigned char *rawBytes = PQunescapeBytea((const unsigned char *)bytes, &length);
            NSData *data = [NSData dataWithBytes:rawBytes length:length];
            PQfreemem((void *)rawBytes);
            return data;
        }
        case VARCHAROID:
        case TEXTOID:
        default:
            return @(bytes);
            break;
    }
    return nil;
}

#pragma mark -
#pragma mark Transactions
- (BOOL)beginTransaction
{
    PGresult *result = PQexec(_connection, "BEGIN");
    if(PQresultStatus(result) != PGRES_COMMAND_OK)
    {
        [NSException raise:@"PostgreSQL error"
                    format:@"Couldn't start transaction, Details: %@", @(PQresultErrorMessage(result))];
        PQclear(result);
        return NO;
    }
    PQclear(result);
    return YES;
}
- (BOOL)rollBack
{
    PGresult *result = PQexec(_connection, "ROLLBACK");
    if(PQresultStatus(result) != PGRES_COMMAND_OK)
    {
        [NSException raise:@"PostgreSQL error"
                    format:@"Couldn't roll back transaction, Details: %@", @(PQresultErrorMessage(result))];
        PQclear(result);
        return NO;
    }
    PQclear(result);
   return YES;
}
- (BOOL)endTransaction
{
    PGresult *result = PQexec(_connection, "COMMIT");
    if(PQresultStatus(result) != PGRES_COMMAND_OK)
    {
        [NSException raise:@"PostgreSQL error"
                    format:@"Couldn't end transaction, Details: %@", @(PQresultErrorMessage(result))];
        PQclear(result);
        return NO;
    }
    PQclear(result);
    return YES;
}
@end

#pragma mark -

static NSRange rangeOfParameterToken(NSString *param, NSString *query)
{
    BOOL inDblQuotes     = NO, inSingleQuotes = NO, escapeNext = NO;
    const char *needle   = [param UTF8String], *haystack = [query UTF8String];
    NSUInteger needleLen = [param length];

    for(int i = 0; i < [query length]; ++i) {
        if(escapeNext)
            escapeNext = NO;
        else if(haystack[i] == '"' && !inSingleQuotes)
            inDblQuotes = !inDblQuotes;
        else if(haystack[i] == '\'' && !inDblQuotes)
            inSingleQuotes = !inSingleQuotes;
        else if(haystack[i] == '\\')
            escapeNext = YES;
        else if(inSingleQuotes || inDblQuotes)
            continue;
        else if(strncmp(haystack+i, needle, needleLen) == 0)
            return (NSRange){ i, needleLen };
    }
    return (NSRange){ NSNotFound, 0 };
}

static NSDateFormatter *pgDateFormatter = nil;
static dispatch_once_t dateFormatterCreated;
static dispatch_block_t createDateFormatter = ^{
    pgDateFormatter = [[NSDateFormatter alloc] init];
    [pgDateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [pgDateFormatter setDateFormat:@"yyyy'-'MM'-'dd HH':'mm':'ssZZ"];
};

static NSString *NSDateToPostgresTimestamp(NSDate *date)
{
    dispatch_once(&dateFormatterCreated, createDateFormatter);
    return [pgDateFormatter stringFromDate:date];
}

static NSDate *NSDateFromPostgresTimestamp(NSString *timestamp)
{
    dispatch_once(&dateFormatterCreated, createDateFormatter);

    if([timestamp rangeOfString:@"."].location != NSNotFound)
        timestamp = [NSString stringWithFormat:@"%@ +0000", [timestamp substringToIndex:[timestamp rangeOfString:@"."].location]];
    else
        timestamp = [NSString stringWithFormat:@"%@ +0000", timestamp];

    return [pgDateFormatter dateFromString:timestamp];
}