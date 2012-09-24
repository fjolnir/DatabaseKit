#import "DBConnectionPool.h"

id DBConnectionRollback = @"DBConnectionRollback";

@interface DBConnectionPool () {
    NSMutableArray *_connections;
}
@property(readwrite, retain) NSURL *URL;
- (DBConnection *)_getConnection:(NSError **)err;
- (void)_addConnection:(DBConnection *)connection;
@end

@implementation DBConnectionPool
+ (DBConnectionPool *)withURL:(NSURL *)URL error:(NSError **)err
{
    DBConnectionPool *pool = [self new];
    pool.URL = URL;
    DBConnection *firstConnection = [pool _getConnection:err];
    if(!firstConnection)
        return nil;
    [pool _addConnection:firstConnection];
    return pool;
}

- (id)init
{
    if(!(self = [super init]))
        return nil;
    _connections = [NSMutableArray array];
    return self;
}

- (id)do:(DBConnectionPoolBlock)block
{
    DBConnection *connection = [self _getConnection:nil];
    id ret = block(connection);
    [self _addConnection:connection];
    return ret;
}

- (id)transaction:(DBConnectionPoolBlock)block
{
    DBConnection *connection = [self _getConnection:nil];
    [connection beginTransaction];
    
    id ret = block(connection);
    
    if(ret == DBConnectionRollback) {
        ret = nil;
        [connection rollBack];
    } else
        [connection endTransaction];

    [self _addConnection:connection];
    return ret;
}

- (DBConnection *)_getConnection:(NSError **)err
{
    @synchronized(self) {
        if([_connections count] > 0) {
            DBConnection *connection = [_connections lastObject];
            [_connections removeLastObject];
            return connection;
        }
        return [DBConnection openConnectionWithURL:_URL error:err];
    }
}
- (void)_addConnection:(DBConnection *)connection
{
    @synchronized(self) {
        [_connections addObject:connection];
    }
}
@end
