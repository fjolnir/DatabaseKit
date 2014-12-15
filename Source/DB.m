#import "DB+Private.h"
#import "DBTable.h"
#import "DBModel+Private.h"
#import "DBCreateTableQuery.h"
#import "DBConnectionQueue.h"

@implementation DB {
    DBConnection *_connection;
    NSMutableSet *_dirtyObjects;
}

+ (DB *)withURL:(NSURL *)URL
{
    return [self withURL:URL error:NULL];
}

+ (DB *)withURL:(NSURL *)URL error:(NSError **)err
{
    return [[self alloc] initWithConnection:[DBConnectionQueue connectionProxyWithURL:URL error:err]];
}

- (instancetype)initWithConnection:(DBConnection *)aConnection
{
    if((self = [self init])) {
        _connection = aConnection;
        _dirtyObjects = [NSMutableSet new];
    }
    return self && _connection ? self : nil;
}

// Returns a table whose name matches key
- (id)objectForKeyedSubscript:(id)key
{
    NSParameterAssert([key isKindOfClass:[NSString class]]);
    return [DBTable withDatabase:self name:key];
}

- (DBCreateTableQuery *)create
{
    return [DBCreateTableQuery withDatabase:self];
}

- (BOOL)save:(NSError **)outErr
{
    @synchronized(_dirtyObjects) {
        if([_dirtyObjects count] > 0)
            return [_connection transaction:^{
                for(DBModel *obj in [_dirtyObjects copy]) {
                    if(![obj _save:outErr])
                        return DBTransactionRollBack;
                }
                [_dirtyObjects removeAllObjects];
                return DBTransactionCommit;
            }];
        else
            return NO;
    }
}

- (void)registerDirtyObject:(DBModel *)obj
{
    NSParameterAssert(obj);
    @synchronized(_dirtyObjects) {
        if(![_dirtyObjects containsObject:obj]) {
            [_dirtyObjects addObject:obj];
            [obj addObserver:self forKeyPath:@"hasChanges" options:0 context:NULL];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"hasChanges"] && [object isKindOfClass:[DBModel class]]) {
        if(![object hasChanges]) {
            [object removeObserver:self forKeyPath:@"hasChanges"];
            @synchronized(_dirtyObjects) {
                [_dirtyObjects removeObject:object];
            }
        }
    }
}

- (void)dealloc
{
    for(DBModel *object in _dirtyObjects) {
        [object removeObserver:self forKeyPath:@"hasChanges"];
    }
}

@end
