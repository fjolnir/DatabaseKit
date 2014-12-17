#define LOG_QUERIES NO

#import "DBSQLiteConnection.h"
#import "DBQuery.h"
#import "DBUtilities.h"
#import "DBISO8601DateFormatter.h"
#import <unistd.h>
#import <sqlite3.h>
#import <dispatch/dispatch.h>

static int _checkSQLiteStatus(int status, sqlite3 *handle, NSError **outErr);
#define CHK(expr) (_checkSQLiteStatus((expr), _handle, outErr))

/*! @cond IGNORE */
@interface DBSQLiteResult : DBResult {
@public
    NSString *_query;
    DBSQLiteConnection *_connection;
    sqlite3_stmt *_stmt;
}
+ (instancetype)resultWithStatement:(sqlite3_stmt *)stmt
                              query:(NSString *)query
                         connection:(DBSQLiteConnection *)connection;
@end

@interface DBSQLiteConnection () {
@public
    sqlite3 *_handle;
    NSMutableDictionary *_cachedStatements;
    NSMutableArray *_savePointStack;
}
- (sqlite3_stmt *)prepareQuerySQL:(NSString *)query
                             tail:(NSString **)outTail
                            error:(NSError **)outError;

- (void)_resultWasDeallocated:(DBSQLiteResult *)result error:(NSError **)outErr;
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


#pragma mark - Initialization

- (instancetype)initWithURL:(NSURL *)URL error:(NSError **)outErr;
{
    if(!(self = [super initWithURL:URL error:outErr]))
        return nil;
    _path = URL ? URL.path : @":memory:";
    _cachedStatements  = [NSMutableDictionary new];

    int flags = SQLITE_OPEN_READWRITE;
    if([URL.query rangeOfString:@"create=yes"].location != NSNotFound)
        flags |= SQLITE_OPEN_CREATE;
    
    int err = sqlite3_open_v2([_path UTF8String], &_handle, flags, NULL);
    if(err != SQLITE_OK) {
        if(outErr)
            *outErr = [NSError errorWithDomain:@"database.sqlite.openerror"
                                       code:DBSQLiteDatabaseNotFoundErrorCode
                                   userInfo:@{
                NSLocalizedDescriptionKey: @(sqlite3_errmsg(_handle)),
                NSFilePathErrorKey:_path
            }];
        return nil;
    }

    [[self execute:@"PRAGMA foreign_keys = ON" substitutions:nil error:NULL] step:NULL];

    return self;
}


#pragma mark - SQL Executing

- (DBResult *)execute:(NSString *)sql substitutions:(id)substitutions error:(NSError **)outErr
{
    static dispatch_once_t onceToken;
    static NSDateFormatter *dateFormatter;
    dispatch_once(&onceToken, ^{
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        dateFormatter.locale     = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    });
    
    BOOL isDict = [substitutions isKindOfClass:[NSDictionary class]] ||
    [substitutions isKindOfClass:[NSMapTable class]];
    NSParameterAssert(!substitutions                                       ||
                      [substitutions isKindOfClass:[NSArray class]]        ||
                      [substitutions isKindOfClass:[NSPointerArray class]] ||
                      isDict);
    DBDebugLog(@"Executing SQL: %@ subs: %@", sql, substitutions);
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
        else if([sub isKindOfClass:[NSString class]])
            CHK(sqlite3_bind_text(queryByteCode, i+1, [sub UTF8String], -1, SQLITE_TRANSIENT));
        else if([sub isKindOfClass:[NSData class]])
            CHK(sqlite3_bind_blob(queryByteCode, i+1, [sub bytes], (int)[sub length], SQLITE_TRANSIENT));
        else if([sub isKindOfClass:[NSNumber class]]) {
            switch (*[sub objCType]) {
                case 'd':
                case 'f':
                    CHK(sqlite3_bind_double(queryByteCode, i+1, [sub doubleValue]));
                    break;
                case 'l':
                case 'L':
                case 'q':
                case 'Q':
                    CHK(sqlite3_bind_int64(queryByteCode, i+1, [sub longLongValue]));
                    break;
                default:
                    CHK(sqlite3_bind_int(queryByteCode, i+1, [sub intValue]));
                    break;
            }
        } else if([sub isMemberOfClass:[NSNull class]])
            CHK(sqlite3_bind_null(queryByteCode, i+1));
        else if([sub isKindOfClass:[NSDate class]])
            CHK(sqlite3_bind_text(queryByteCode, i+1, [[dateFormatter stringFromDate:sub] UTF8String], -1, SQLITE_TRANSIENT));
        else if([sub conformsToProtocol:@protocol(NSCoding)]) {
            NSData *serialized = [NSKeyedArchiver archivedDataWithRootObject:sub];
            CHK(sqlite3_bind_blob(queryByteCode, i+1, serialized.bytes, (int)serialized.length, SQLITE_TRANSIENT));
        } else
            [NSException raise:@"Unrecognized object type"
                        format:@"DBKit doesn't know how to handle this type of object: %@ class: %@", sub, [sub class]];
    }

    DBResult *result = [DBSQLiteResult resultWithStatement:queryByteCode query:tail ? nil : sql connection:self];
    if(tail) {
        while([result step:outErr] == DBResultStateNotAtEnd);
        if(result.state != DBResultStateAtEnd)
            return nil;
        else
            return [self execute:tail
                   substitutions:substitutions
                           error:outErr];
    } else
        return result;
}

- (void)_resultWasDeallocated:(DBSQLiteResult *)result error:(NSError **)outErr
{
    NSParameterAssert(result);
    if(result->_query) {
        CHK(sqlite3_reset(result->_stmt));
        _cachedStatements[result->_query] = [NSValue valueWithPointer:result->_stmt];
    } else
        CHK(sqlite3_finalize(result->_stmt));
}

- (BOOL)executeUpdate:(NSString *)sql substitutions:(id)substitutions error:(NSError **)outErr
{
    return [[self execute:sql substitutions:substitutions error:outErr] step:outErr] == DBResultStateAtEnd;
}

- (NSArray *)tableNames
{
    DBResult *result = [self execute:@"SELECT `name` FROM `sqlite_master` WHERE `type`='table'"
                       substitutions:nil
                               error:NULL];
    return [[result toArray:NULL] valueForKey:@"name"];
}

- (BOOL)tableExists:(NSString *)tableName
{
    DBResult *result = [self execute:@"SELECT COUNT(*) FROM `sqlite_master` WHERE (`type`='table' OR `type`='view') AND `name`=$1"
                       substitutions:@[tableName]
                               error:NULL];

    if([result step:NULL] == DBResultStateNotAtEnd)
        return [[result valueOfColumnAtIndex:0] unsignedIntegerValue] > 0;
    else
        return NO;
}

- (NSDictionary *)columnsForTable:(NSString *)tableName
{
    DBResult *result = [self execute:[NSString stringWithFormat:@"PRAGMA table_info(`%@`)", tableName]
                       substitutions:nil
                               error:NULL];
    if([result step:NULL] == DBResultStateNotAtEnd) {
        NSMutableDictionary *columns = [NSMutableDictionary new];
        do {
            [columns setObject:@([[self class] typeForSql:[result valueOfColumnNamed:@"type"]])
                        forKey:[result valueOfColumnNamed:@"name"]];
        } while([result step:NULL] == DBResultStateNotAtEnd);
        return columns;
    } else
        return nil;
}

- (BOOL)closeConnection:(NSError **)outErr
{
    for(NSValue *query in _cachedStatements.allValues) {
        CHK(sqlite3_finalize([query pointerValue]));
    }
    [_cachedStatements removeAllObjects];

    int err = CHK(sqlite3_close(_handle));
    _handle = NULL;
    return err == SQLITE_OK;
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
        CHK(sqlite3_reset(queryByteCode));
        return queryByteCode;
    }

    const char *tailBuf = NULL;
    int err = CHK(sqlite3_prepare_v2(_handle,
                                     [query UTF8String],
                                     (int)[query lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                                     &queryByteCode,
                                     &tailBuf));
    if(err != SQLITE_OK || queryByteCode == NULL)
        return NULL;

    NSString *tail = [@(tailBuf) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(aoTail && [tail length] > 0)
        *aoTail = tail;

    return queryByteCode;
}


#pragma mark - Transactions

- (BOOL)beginTransaction:(NSError **)outErr
{
    NSString * const savePointName = [[NSUUID UUID] UUIDString];
    char *errorMessage;
    int err = sqlite3_exec(_handle,
                           [[NSString stringWithFormat:@"SAVEPOINT '%@'", savePointName] UTF8String],
                           NULL, NULL, &errorMessage);
    if(err != SQLITE_OK) {
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

- (BOOL)rollBack:(NSError **)outErr
{
    NSAssert([_savePointStack count] > 0, @"Not in a transaction");
    char *errorMessage;
    int err = sqlite3_exec(_handle,
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
- (BOOL)endTransaction:(NSError **)outErr
{
    NSAssert([_savePointStack count] > 0, @"Not in a transaction");
    char *errorMessage;
    int err = sqlite3_exec(_handle,
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


#pragma mark - Cleanup

- (void)dealloc
{
    [self closeConnection:NULL];
}
@end


@implementation DBSQLiteResult

+ (instancetype)resultWithStatement:(sqlite3_stmt *)stmt
                              query:(NSString *)query
                         connection:(DBSQLiteConnection *)connection
{
    DBSQLiteResult *result = [self new];
    result->_query = query;
    result->_connection = connection;
    result->_stmt = stmt;
    return result;
}

- (DBResultState)step:(NSError **)outErr
{
retry:
    switch(sqlite3_step(_stmt)) {
        case SQLITE_BUSY:
            usleep(100);
            goto retry;
        case SQLITE_ROW:
            _state = DBResultStateNotAtEnd;
            break;
        case SQLITE_DONE:
            _state = DBResultStateAtEnd;
            break;
        default:
            if(outErr)
                *outErr = [NSError errorWithDomain:DBConnectionErrorDomain
                                              code:0
                                          userInfo:@{
                    NSLocalizedDescriptionKey: @(sqlite3_errmsg(_connection->_handle)),
                    @"query": _query ?: @""
                }];
            _state = DBResultStateError;
            break;
    }
    return _state;
}

- (NSUInteger)columnCount
{
    return sqlite3_column_count(_stmt);
}

- (NSString *)nameOfColumnAtIndex:(NSUInteger)idx
{
    NSParameterAssert(idx < self.columnCount && idx < INT_MAX);
    return @(sqlite3_column_name(_stmt, (int)idx));
}

- (NSUInteger)indexOfColumnNamed:(NSString *)name
{
    const char *nameBuf = [name UTF8String];
    for(int i = 0; i < self.columnCount; ++i) {
        if(strcmp(nameBuf, sqlite3_column_name(_stmt, i)) == 0)
            return i;
    }
    return NSNotFound;
}

- (id)valueOfColumnAtIndex:(NSUInteger)idx
{
    static dispatch_once_t onceToken;
    static DBISO8601DateFormatter *dateFormatter;
    dispatch_once(&onceToken, ^{
        dateFormatter = [DBISO8601DateFormatter new];
    });

    int columnType = sqlite3_column_type(_stmt, (int)idx);
    switch(columnType)
    {
        case SQLITE_INTEGER:
            return @(sqlite3_column_int(_stmt, (int)idx));
            break;
        case SQLITE_FLOAT:
            return @(sqlite3_column_double(_stmt, (int)idx));
            break;
        case SQLITE_BLOB:
            return [NSData dataWithBytes:sqlite3_column_blob(_stmt, (int)idx)
                                  length:sqlite3_column_bytes(_stmt, (int)idx)];
            break;
        case SQLITE_NULL:
            return [NSNull null];
            break;
        case SQLITE_TEXT: {
            const char *declType = sqlite3_column_decltype(_stmt, (int)idx);
            if(declType && strncmp("date", declType, 4) == 0)
                return [dateFormatter dateFromString:@((char *)sqlite3_column_text(_stmt, (int)idx))];
            else
                return @((char *)sqlite3_column_text(_stmt, (int)idx));
            break;
        } default:
            // It really shouldn't ever come to this.
            break;
    }
    return nil;
}

- (void)dealloc
{
    if(_connection)
        [_connection _resultWasDeallocated:self error:NULL];
    else
        sqlite3_finalize(_stmt);
}
@end

static int _checkSQLiteStatus(int status, sqlite3 *handle, NSError **outErr)
{
    if(status != SQLITE_OK) {
        const char *err = sqlite3_errmsg(handle);
        if(outErr)
            *outErr = [NSError errorWithDomain:DBConnectionErrorDomain
                                          code:0
                                      userInfo:@{
                                                 NSLocalizedDescriptionKey: @(err)
                                                 }];
        else
            NSLog(@"Sqlite error: '%s'", err);
    }
    return status;
}
