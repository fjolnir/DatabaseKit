#import "DB.h"
#import "DBModel+Private.h"
#import "DBTable.h"
#import "DBCreateTableQuery.h"
#import "DBConnectionPool.h"
#import <pthread.h>

static void releaseLiveObjects(void *ptr) {
    __unused id objs = (__bridge_transfer id)ptr;
}

@interface DB ()
@property(readwrite, strong) DBConnection *connection;
@end

@implementation DB {
    OSSpinLock _liveObjectLock;
    NSMapTable *_liveObjectStorage;
}

+ (DB *)withURL:(NSURL *)URL
{
    return [self withURL:URL error:NULL];
}

+ (DB *)withURL:(NSURL *)URL error:(NSError **)err
{
    return [[self alloc] initWithConnection:(DBConnection *)[DBConnectionPool connectionProxyWithURL:URL error:err]];
}

- (instancetype)init
{
    if((self = [super init])) {
        _liveObjectLock = OS_SPINLOCK_INIT;
        _liveObjectStorage = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}
- (instancetype)initWithConnection:(DBConnection *)aConnection
{
    if((self = [self init]))
        _connection = aConnection;
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

@end

@implementation DB (DBModelUniquing)

- (NSMapTable *)liveObjectsOfModelClass:(Class)modelClass
{
    NSParameterAssert([modelClass isSubclassOfClass:[DBModel class]]);

    OSSpinLockLock(&_liveObjectLock);
    NSMapTable *liveObjects = [_liveObjectStorage objectForKey:modelClass];
    if(!liveObjects) {
        liveObjects = [NSMapTable strongToWeakObjectsMapTable];
        [_liveObjectStorage setObject:liveObjects forKey:modelClass];
    }
    OSSpinLockUnlock(&_liveObjectLock);
    return liveObjects;
}

@end
