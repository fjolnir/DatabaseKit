#define LOG_QUERIES NO

#import "DBSQLiteConnection.h"
#import "DBQuery.h"
#import "DBUtilities.h"
#import "DBISO8601DateFormatter.h"
#import "DBPointerCollectionAdditions.h"
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
    NSMapTable *_cachedStatements;
    NSHashTable *_openStatements;
    NSMutableArray *_savePointStack;
}
- (sqlite3_stmt *)compileQuery:(NSString *)query
                          tail:(NSString **)outTail
                         error:(NSError **)outError;

- (BOOL)_resultWasDeallocated:(DBSQLiteResult *)result error:(NSError **)outErr;
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
    _cachedStatements = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPersonality
                                              valueOptions:NSPointerFunctionsOpaqueMemory|NSPointerFunctionsOpaquePersonality];
    _openStatements   = [NSHashTable hashTableWithOptions:NSPointerFunctionsOpaqueMemory|NSPointerFunctionsOpaquePersonality];

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
    sqlite3_stmt *stmt = [self compileQuery:sql
                                       tail:&tail
                                      error:&prepareErr];
    if(!stmt) {
        if(outErr) *outErr = prepareErr;
        DBLog(@"Unable to prepare bytecode for SQLite query: '%@': %@", sql, [prepareErr localizedDescription]);
        return nil;
    }

    const char *keyCstring;
    NSString *key;
    id sub;
    for(int i = 0; i < sqlite3_bind_parameter_count(stmt); ++i) {
        if(isDict) {
            keyCstring = sqlite3_bind_parameter_name(stmt, i);
            if(!keyCstring)
                continue;
            key = [@(keyCstring) stringByReplacingOccurrencesOfString:@":" withString:@""];
            sub = substitutions[key];
        } else
            sub = substitutions[i];
        
        if(!sub)
            continue;
        else if([sub isKindOfClass:[NSString class]])
            CHK(sqlite3_bind_text(stmt, i+1, [sub UTF8String], -1, SQLITE_TRANSIENT));
        else if([sub isKindOfClass:[NSUUID class]]) {
            uuid_t bytes;
            [sub getUUIDBytes:bytes];
            CHK(sqlite3_bind_blob(stmt, i+1, bytes, sizeof(bytes), SQLITE_TRANSIENT));
        }
    else if([sub isKindOfClass:[NSData class]])
            CHK(sqlite3_bind_blob(stmt, i+1, [sub bytes], (int)[sub length], SQLITE_TRANSIENT));
        else if([sub isKindOfClass:[NSNumber class]]) {
            switch (*[sub objCType]) {
                case 'd':
                case 'f':
                    CHK(sqlite3_bind_double(stmt, i+1, [sub doubleValue]));
                    break;
                case 'l':
                case 'L':
                case 'q':
                case 'Q':
                    CHK(sqlite3_bind_int64(stmt, i+1, [sub longLongValue]));
                    break;
                default:
                    CHK(sqlite3_bind_int(stmt, i+1, [sub intValue]));
                    break;
            }
        } else if([sub isMemberOfClass:[NSNull class]])
            CHK(sqlite3_bind_null(stmt, i+1));
        else if([sub isKindOfClass:[NSDate class]])
            CHK(sqlite3_bind_text(stmt, i+1, [[dateFormatter stringFromDate:sub] UTF8String], -1, SQLITE_TRANSIENT));
        else if([sub conformsToProtocol:@protocol(NSCoding)]) {
            NSData *serialized = [NSKeyedArchiver archivedDataWithRootObject:sub];
            CHK(sqlite3_bind_blob(stmt, i+1, serialized.bytes, (int)serialized.length, SQLITE_TRANSIENT));
        } else
            [NSException raise:@"Unrecognized object type"
                        format:@"DBKit doesn't know how to handle this type of object: %@ class: %@", sub, [sub class]];
    }

    DBResult *result = [DBSQLiteResult resultWithStatement:stmt query:tail ? nil : sql connection:self];
    DBHashTableInsert(_openStatements, stmt);
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

- (BOOL)_resultWasDeallocated:(DBSQLiteResult *)result error:(NSError **)outErr
{
    NSParameterAssert(result);
    if(DBHashTableGet(_openStatements, result->_stmt)) {
        DBHashTableRemove(_openStatements, result->_stmt);
        if(result->_query) {
            if(CHK(sqlite3_reset(result->_stmt)) == SQLITE_OK) {
                DBMapTableInsert(_cachedStatements, (__bridge void *)result->_query, result->_stmt);
                return YES;
            }
        }
        return CHK(sqlite3_finalize(result->_stmt)) == SQLITE_OK;
    } else
        return YES;
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
            [columns setObject:@([self.class typeForSql:[result valueOfColumnNamed:@"type"]])
                        forKey:[result valueOfColumnNamed:@"name"]];
        } while([result step:NULL] == DBResultStateNotAtEnd);
        return columns;
    } else
        return nil;
}

- (BOOL)closeConnection:(NSError **)outErr
{
    for(NSString *query in _cachedStatements) {
        CHK(sqlite3_finalize(DBMapTableGet(_cachedStatements, (__bridge void *)query)));
    }
    DBResetMapTable(_cachedStatements);

    DBEnumerateHashTable(_openStatements, ^(void *stmt) {
        CHK(sqlite3_finalize(stmt));
    });
    DBResetHashTable(_openStatements);

    int err = CHK(sqlite3_close(_handle));
    _handle = NULL;
    return err == SQLITE_OK;
}

- (sqlite3_stmt *)compileQuery:(NSString *)query
                          tail:(NSString **)aoTail
                         error:(NSError **)outErr
{
    if(LOG_QUERIES)
        DBDebugLog(@"Preparing query: %@", query);

    // Prepare the query
    sqlite3_stmt *stmt = DBMapTableGet(_cachedStatements, (__bridge void *)query);
    if(stmt) {
        CHK(sqlite3_reset(stmt));
        return stmt;
    }

    const char *tailBuf = NULL;
    int err = CHK(sqlite3_prepare_v2(_handle,
                                     [query UTF8String],
                                     (int)[query lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                                     &stmt,
                                     &tailBuf));
    if(err != SQLITE_OK || stmt == NULL)
        return NULL;

    NSString *tail = [@(tailBuf) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(aoTail && tail.length > 0)
        *aoTail = tail;

    return stmt;
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
    NSAssert(_savePointStack.count > 0, @"Not in a transaction");
    char *errorMessage;
    int err = sqlite3_exec(_handle,
                           [[NSString stringWithFormat:@"ROLLBACK TO SAVEPOINT '%@'", [_savePointStack lastObject]] UTF8String],
                           NULL, NULL, &errorMessage);
    if(err != SQLITE_OK)
    {
        if(outErr)
            *outErr = [NSError errorWithDomain:DBConnectionErrorDomain
                                          code:0
                                      userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to roll back transaction: %@",  @(errorMessage)]
            }];
        return NO;
    }
    [_savePointStack removeLastObject];
    return YES;
}
- (BOOL)endTransaction:(NSError **)outErr
{
    NSAssert(_savePointStack.count > 0, @"Not in a transaction");
    char *errorMessage;
    int err = sqlite3_exec(_handle,
                           [[NSString stringWithFormat:@"RELEASE SAVEPOINT '%@'", [_savePointStack lastObject]] UTF8String],
                           NULL, NULL, &errorMessage);
    if(err != SQLITE_OK)
    {
        if(outErr)
            *outErr = [NSError errorWithDomain:DBConnectionErrorDomain
                                          code:0
                                      userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to commit transaction: %@",  @(errorMessage)]
            }];
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
    const char *declType;
    switch(columnType)
    {
        case SQLITE_INTEGER:
            return @(sqlite3_column_int(_stmt, (int)idx));
            break;
        case SQLITE_FLOAT:
            return @(sqlite3_column_double(_stmt, (int)idx));
            break;
        case SQLITE_BLOB:
            declType = sqlite3_column_decltype(_stmt, (int)idx);
            if(declType && strncmp([[_connection.class sqlForType:DBTypeUUID] UTF8String], declType, 9) == 0) {
                NSAssert(sqlite3_column_bytes(_stmt, (int)idx) == sizeof(uuid_t),
                         @"UUID column value was of an invalid length!");
                return [[NSUUID alloc] initWithUUIDBytes:sqlite3_column_blob(_stmt, (int)idx)];
            } else
                return [NSData dataWithBytes:sqlite3_column_blob(_stmt, (int)idx)
                                      length:sqlite3_column_bytes(_stmt, (int)idx)];
            break;
        case SQLITE_NULL:
            return [NSNull null];
            break;
        case SQLITE_TEXT:
            declType = sqlite3_column_decltype(_stmt, (int)idx);
            if(declType && strncmp([[_connection.class sqlForType:DBTypeDate] UTF8String], declType, 4) == 0)
                return [dateFormatter dateFromString:@((char *)sqlite3_column_text(_stmt, (int)idx))];
            else
                return @((char *)sqlite3_column_text(_stmt, (int)idx));
            break;
        default:
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
