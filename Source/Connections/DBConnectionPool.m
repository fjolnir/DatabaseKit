#import "DBConnectionPool.h"
#import "DBConnection.h"
#import "DBUtilities.h"
#import <pthread.h>

static void _onThreadExit(void *connection)
{
    CFRelease(connection);
}

@implementation DBConnectionPool {
    NSHashTable *_connections;
    pthread_key_t _threadLocalKey;
}

+ (instancetype)alloc
{
    DBConnectionPool *pool = [super alloc];
    if(pool) {
        pool->_connections = [NSHashTable weakObjectsHashTable];
        pthread_key_create(&pool->_threadLocalKey, _onThreadExit);
    }
    return pool;
}

- (void)dealloc
{
    pthread_key_delete(_threadLocalKey);
    @synchronized(_connections) {
        for(DBConnection *connection in _connections) {
            CFRelease((__bridge void *)connection);
        }
    }
}

- (DBConnection *)connection:(NSError **)err
{
    DBConnection *connection = (__bridge id)pthread_getspecific(_threadLocalKey);
    if(!connection) {
        connection = [DBConnection openConnectionWithURL:self.connectionURL error:err];
        if(!connection)
            return nil;
        pthread_setspecific(_threadLocalKey, (__bridge_retained void *)connection);
        @synchronized(_connections) {
            [_connections addObject:connection];
        }
    }
    return connection;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return self.connection;
}

- (BOOL)closeConnection:(NSError **)outErr
{
    @synchronized(_connections) {
        BOOL ret = YES;
        for(DBConnection *connection in _connections) {
            BOOL const succ = [connection closeConnection:outErr];
            if(!succ) {
                ret = NO;
                DBLog(@"Failed to close %@ in pool %@", connection, self);
            }
        }
        return ret;
    }
}

@end
