#import "DBConnectionPool.h"
#import <pthread.h>

@interface DBConnectionPool () {
    NSMutableArray *_connections;
    pthread_key_t _threadLocalKey;
}
@property(readwrite, retain) NSURL *URL;
- (DBConnection *)_getConnection:(NSError **)err;
@end

static void _connectionCloser(void *ptr)
{
    DBConnection *connection = (__bridge id)ptr;
    [connection closeConnection];
}

@implementation DBConnectionPool
+ (DBConnection *)openConnectionWithURL:(NSURL *)URL error:(NSError **)err
{
    DBConnectionPool *pool = [self new];
    pool.URL = URL;
    DBConnection *firstConnection = [pool _getConnection:err];
    if(!firstConnection)
        return nil;
    return pool;
}

- (id)init
{
    if(!(self = [super init]))
        return nil;
    _connections = [NSMutableArray array];
    pthread_key_create(&_threadLocalKey, &_connectionCloser);
    return self;
}

- (void)dealloc
{
    pthread_key_delete(_threadLocalKey);
}

- (DBConnection *)_getConnection:(NSError **)err
{
    DBConnection *connection = (__bridge id)pthread_getspecific(_threadLocalKey);
    if(!connection) {
        connection = [DBConnection openConnectionWithURL:self.URL error:err];
        if(!connection)
            return nil;
        pthread_setspecific(_threadLocalKey, (__bridge void *)connection);
        @synchronized(self) { // Replace with a spinlock?
            [_connections addObject:connection];
        }
    }
    return connection;
}


#pragma mark - Forwarders

- (NSArray *)executeSQL:(NSString *)sql substitutions:(id)substitutions error:(NSError **)outErr
{
    return [[self _getConnection:outErr] executeSQL:sql substitutions:substitutions error:outErr];
}
- (BOOL)closeConnection
{
    if([_connections count] == 0)
        return YES;
    BOOL ret = NO;
    for(DBConnection *connection in _connections) {
        ret |= [connection closeConnection];
    }
    return ret;
}
- (NSArray *)columnsForTable:(NSString *)tableName
{
    return [[self _getConnection:nil] columnsForTable:tableName];
}
- (BOOL)beginTransaction
{
    return [[self _getConnection:nil] beginTransaction];
}
- (BOOL)rollBack
{
    return [[self _getConnection:nil] rollBack];
}
- (BOOL)endTransaction
{
    return [[self _getConnection:nil] endTransaction];
}
- (NSUInteger)lastInsertId
{
    return [[self _getConnection:nil] lastInsertId];
}

@end
