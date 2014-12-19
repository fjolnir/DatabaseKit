#import "DB+Private.h"
#import "DBTable.h"
#import "DBModel+Private.h"
#import "DBCreateTableQuery.h"
#import "DBDeleteQuery.h"
#import "DBConnectionPool.h"
#import <libkern/OSAtomic.h>

@implementation DB {
    DBConnection *_connection;
    NSMutableSet *_dirtyObjects;
    NSMutableDictionary *_tables;
    OSSpinLock _tableLock;
}

+ (DB *)withURL:(NSURL *)URL
{
    return [self withURL:URL error:NULL];
}

+ (DB *)withURL:(NSURL *)URL error:(NSError **)err
{
    return [[self alloc] initWithConnection:[DBConnectionPool connectionProxyWithURL:URL error:err]];
}

- (instancetype)init
{
    if((self = [super init]))
        _tableLock = OS_SPINLOCK_INIT;
    return self;
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
     OSSpinLockLock(&_tableLock);
     DBTable *table = _tables[key];
     if(!table && [_connection tableExists:key]) {
         table = [DBTable withDatabase:self name:key];
         if(!_tables)
             _tables = [NSMutableDictionary dictionaryWithObject:table forKey:key];
         else
             _tables[key] = table;
     }
     OSSpinLockUnlock(&_tableLock);
     return table;
 }

- (DBCreateTableQuery *)create
{
    return [DBCreateTableQuery withDatabase:self];
}

- (BOOL)saveObjects:(NSError **)outErr
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

- (void)registerObject:(DBModel *)object
{
    NSParameterAssert(object && !object.database);

    object.database = self;
    [self registerDirtyObject:object];
}
- (void)removeObject:(DBModel *)object
{
    NSParameterAssert(object.database == self);

    if(object.saved)
        [[object.query delete] execute:NULL];
    object.database = nil;
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
