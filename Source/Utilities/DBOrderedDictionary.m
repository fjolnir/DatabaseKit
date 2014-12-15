#import "DBOrderedDictionary.h"

@implementation DBOrderedDictionary {
    NSMutableOrderedSet *_keys;
    NSMutableDictionary *_pairs;
}

- (id)init
{
    if((self = [super init])) {
        _keys = [NSMutableOrderedSet new];
        _pairs = [NSMutableDictionary new];
    }
    return self;
}
- (id)initWithCapacity:(NSUInteger)capacity
{
    if((self = [super init])) {
        _keys = [[NSMutableOrderedSet alloc] initWithCapacity:capacity];
        _pairs = [[NSMutableDictionary alloc] initWithCapacity:capacity];
    }
    return self;
}

- (instancetype)initWithObjects:(const id [])objects forKeys:(const id<NSCopying> [])keys count:(NSUInteger)cnt
{
    if((self = [super init])) {
        _keys = [[NSMutableOrderedSet alloc] initWithObjects:keys count:cnt];
        _pairs = [[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys count:cnt];
    }
    return self;
}

- (NSUInteger)count
{
    return [_keys count];
}

- (id)objectForKey:(id)aKey
{
    return _pairs[aKey];
}

- (NSEnumerator *)keyEnumerator
{
    return [_keys objectEnumerator];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    return _pairs[_keys[idx]];
}

- (void)setObject:(id)anObject forKey:(id)aKey
{
    if([_keys containsObject:_keys])
        [_keys removeObject:aKey];
    [_keys addObject:aKey];
    _pairs[aKey] = anObject;
}

- (void)removeObjectForKey:(id)aKey
{
    [_keys removeObject:aKey];
    [_pairs removeObjectForKey:aKey];
}

@end
