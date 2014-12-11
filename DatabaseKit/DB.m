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
    pthread_key_t _liveObjectKey;
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
    if((self = [super init]))
        pthread_key_create(&_liveObjectKey, &releaseLiveObjects);
    return self;
}
- (instancetype)initWithConnection:(DBConnection *)aConnection
{
    if((self = [self init]))
        _connection = aConnection;
    return self && _connection ? self : nil;
}

- (void)dealloc
{
    pthread_key_delete(_liveObjectKey);
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

    NSMapTable *storage = (__bridge id)pthread_getspecific(_liveObjectKey);
    if(!storage) {
        storage = [NSMapTable strongToStrongObjectsMapTable];
        pthread_setspecific(_liveObjectKey, (__bridge_retained void *)storage);
    }

    NSMapTable *liveObjects = [storage objectForKey:modelClass];
    if(!liveObjects) {
        liveObjects = [NSMapTable strongToWeakObjectsMapTable];
        [storage setObject:liveObjects forKey:modelClass];
    }
    return liveObjects;
}

@end
