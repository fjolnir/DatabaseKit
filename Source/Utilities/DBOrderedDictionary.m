#import "DBOrderedDictionary.h"

@implementation DBOrderedDictionary {
    NSMutableArray *_keys;
    NSMapTable *_pairs;
}

- (id)init
{
    if((self = [super init])) {
        _keys  = [NSMutableArray new];
        _pairs = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}

- (id)initWithCapacity:(NSUInteger)capacity
{
    if((self = [super init])) {
        _keys  = [[NSMutableArray alloc] initWithCapacity:capacity];
        _pairs = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}

- (instancetype)initWithObjects:(const id [])objects forKeys:(const id<NSCopying> [])keys count:(NSUInteger)cnt
{
    if((self = [super init])) {
        _keys  = [[NSMutableArray alloc] initWithCapacity:cnt];
        _pairs = [NSMapTable strongToStrongObjectsMapTable];
        for(NSUInteger i = 0; i < cnt; ++i) {
            id copiedKey = [keys[i] copyWithZone:NULL];
            [_keys addObject:copiedKey];
            [_pairs setObject:objects[i] forKey:copiedKey];
        }
    }
    return self;
}

- (NSUInteger)count
{
    return [_keys count];
}

- (id)objectForKey:(id)aKey
{
    return [_pairs objectForKey:aKey];
}

- (NSEnumerator *)keyEnumerator
{
    return [_keys objectEnumerator];
}

- (id)objectAtIndex:(NSUInteger)idx
{
    return self[idx];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    return [_pairs objectForKey:_keys[idx]];
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    NSUInteger idx = [_keys indexOfObject:aKey];
    if(idx != NSNotFound)
        [_keys removeObjectAtIndex:idx];

    id copiedKey = [aKey copyWithZone:NULL];
    [_keys addObject:copiedKey];
    [_pairs setObject:anObject forKey:copiedKey];
}

- (void)removeObjectForKey:(id<NSCopying>)aKey
{
    [_keys removeObject:aKey];
    [_pairs removeObjectForKey:aKey];
}

@end
