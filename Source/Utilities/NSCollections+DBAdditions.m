#import "NSCollections+DBAdditions.h"

@implementation NSArray (DBAdditions)
- (NSArray *)db_map:(DBMapBlock)blk
{
    NSParameterAssert(blk);

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    for(id obj in self) {
        [result addObject:blk(obj)];
    }
    return result;
}
- (NSArray *)db_filter:(DBFilterBlock)blk
{
    NSParameterAssert(blk);

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    for(id obj in self) {
        if(blk(obj))
            [result addObject:obj];
    }
    return result;
}
@end

@implementation NSSet (DBAdditions)
- (NSSet *)db_map:(DBMapBlock)blk
{
    NSParameterAssert(blk);

    NSMutableSet *result = [NSMutableSet setWithCapacity:self.count];
    for(id obj in self) {
        [result addObject:blk(obj)];
    }
    return result;
}
- (NSSet *)db_filter:(DBFilterBlock)blk
{
    NSParameterAssert(blk);

    NSMutableSet *result = [NSMutableSet setWithCapacity:self.count];
    for(id obj in self) {
        if(blk(obj))
            [result addObject:obj];
    }
    return result;
}
@end

@implementation NSDictionary (DBAdditions)
- (NSDictionary *)db_mapKeys:(DBMapBlock)blk
{
    NSParameterAssert(blk);
    
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:self.count];
    for(id key in self) {
        result[blk(key)] = self[key];
    }
    return result;
}
- (NSDictionary *)db_filterKeys:(DBFilterBlock)blk
{
    NSParameterAssert(blk);
    
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:self.count];
    for(id key in self) {
        if(blk(key))
            result[key] = self[key];
    }
    return result;
}
@end
