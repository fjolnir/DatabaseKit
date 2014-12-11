#import "DBConnectionPool.h"
#import "DBConnection.h"
#import "Debug.h"
#import <pthread.h>

@interface DBConnectionPool () {
    NSMutableArray *_connections;
    pthread_key_t _threadLocalKey;
}
@end

static void _connectionCloser(void *ptr)
{
    DBConnection *connection = (__bridge_transfer id)ptr;
    [connection closeConnection];
    connection = nil; // Just to make the release explicit
}

@implementation DBConnectionPool

+ (instancetype)connectionProxyWithURL:(NSURL *)URL error:(NSError **)err
{
    DBConnectionPool *pool = [super connectionProxyWithURL:URL error:err];
    if(pool) {
        pool->_connections = [NSMutableArray new];
        pthread_key_create(&pool->_threadLocalKey, &_connectionCloser);
        if(![pool connection:err])
            return nil;
    }
    return pool;
}

- (void)dealloc
{
    pthread_key_delete(_threadLocalKey);
}

- (DBConnection *)connection:(NSError **)err
{
    DBConnection *connection = (__bridge id)pthread_getspecific(_threadLocalKey);
    if(!connection) {
        connection = [DBConnection openConnectionWithURL:self.connectionURL error:err];
        if(!connection)
            return nil;
        pthread_setspecific(_threadLocalKey, (__bridge_retained void *)connection);
        @synchronized(_connections) { // Replace with a spinlock?
            [_connections addObject:connection];
        }
    }
    return connection;
}

- (BOOL)closeConnection
{
    @synchronized(_connections) {
        if([_connections count] == 0)
            return YES;
        BOOL ret = NO;
        for(DBConnection *connection in _connections) {
            BOOL const succ = [connection closeConnection];
            if(!succ)
                DBLog(@"Failed to close %@ in  connection pool %@", connection, self);
            ret |= succ;
        }
        return ret;
    }
}

@end
