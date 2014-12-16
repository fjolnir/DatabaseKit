#import "NSSet+DBAdditions.h"

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
