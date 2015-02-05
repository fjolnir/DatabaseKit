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
    NSMapTable *_liveObjects;
    OSSpinLock _tableLock, _dirtyObjectLock, _liveObjectLock;
    dispatch_queue_t _objectModificationQueue;
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
    if((self = [super init])) {
        _tableLock       = OS_SPINLOCK_INIT;
        _liveObjectLock  = OS_SPINLOCK_INIT;
        _dirtyObjectLock = OS_SPINLOCK_INIT;
        
        _objectModificationQueue = dispatch_queue_create("DB.objectModificationQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
- (instancetype)initWithConnection:(DBConnection *)aConnection
{
    if((self = [self init])) {
        _connection   = aConnection;
        _liveObjects  = [NSMapTable strongToWeakObjectsMapTable];
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
    return [self saveObjectsReplacingExisting:NO error:outErr];
}

- (BOOL)saveObjectsReplacingExisting:(BOOL const)replaceExisting error:(NSError **)outErr;
{
    OSSpinLockLock(&_dirtyObjectLock);
    if(_connection && _dirtyObjects.count > 0) {
        return [_connection transaction:^{
            for(DBModel *obj in _dirtyObjects) {
                if(![obj _executePendingQueriesReplacingExisting:replaceExisting error:outErr]) {
                    OSSpinLockUnlock(&_dirtyObjectLock);
                    return DBTransactionRollBack;
                }
            }
            [_dirtyObjects removeAllObjects];
            OSSpinLockUnlock(&_dirtyObjectLock);
            return DBTransactionCommit;
        } error:outErr];
    }
    else {
        OSSpinLockUnlock(&_dirtyObjectLock);
        return NO;
    }
}

- (void)registerObject:(DBModel *)object
{
    NSParameterAssert(object && !object.database);

    OSSpinLockLock(&_liveObjectLock);
    object.database = self;
    [_liveObjects setObject:object forKey:object.UUID];
    if(!object.saved || object.pendingQueries.count > 0)
        [self registerDirtyObject:object];
    OSSpinLockUnlock(&_liveObjectLock);
}

- (id)objectWithUUID:(NSUUID *)UUID ofModelClass:(Class)aClass
{
    NSParameterAssert(UUID && [aClass isSubclassOfClass:[DBModel class]]);
    
    OSSpinLockLock(&_liveObjectLock);
    DBModel *obj = [_liveObjects objectForKey:UUID];
    if(!obj) {
        obj = [[aClass alloc] initWithUUID:UUID];
        obj.database = self;
        [_liveObjects setObject:obj forKey:UUID];
    }
    OSSpinLockUnlock(&_liveObjectLock);
    return obj;
}
- (void)registerObjects:(id<NSFastEnumeration>)aObjects
{
    for(DBModel *object in aObjects) {
        NSParameterAssert([object isKindOfClass:[DBModel class]]);
        [self registerObject:object];
    }
}
- (void)removeObject:(DBModel *)object
{
    NSParameterAssert(object.database == self);

    OSSpinLockLock(&_liveObjectLock);
    if(object.saved)
        [[object.query delete] execute:NULL];
    object.database = nil;
    [_liveObjects removeObjectForKey:object.UUID];
    OSSpinLockUnlock(&_liveObjectLock);
}

- (void)registerDirtyObject:(DBModel *)obj
{
    NSParameterAssert(obj);
    OSSpinLockLock(&_dirtyObjectLock);
    if(![_dirtyObjects containsObject:obj]) {
        [_dirtyObjects addObject:obj];
        [obj addObserver:self forKeyPath:@"hasChanges" options:0 context:NULL];
    }
    OSSpinLockUnlock(&_dirtyObjectLock);
}


- (BOOL)modify:(void (^)())modificationBlock error:(NSError **)outErr
{
    __block BOOL result;
    dispatch_sync(_objectModificationQueue, ^{
        modificationBlock();
        result = [self saveObjects:outErr];
    });
    return result;
}
- (void)modify:(void (^)())modificationBlock
{
    NSError *err;
    if(![self modify:modificationBlock error:&err])
        [NSException raise:NSInternalInconsistencyException
                    format:@"Failed to save objects. (Error: '%@')", err.localizedDescription];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"hasChanges"] && [object isKindOfClass:[DBModel class]]) {
        if(![object hasChanges]) {
            [object removeObserver:self forKeyPath:@"hasChanges"];
            if(OSSpinLockTry(&_dirtyObjectLock)) {
                [_dirtyObjects removeObject:object];
                OSSpinLockUnlock(&_dirtyObjectLock);
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
