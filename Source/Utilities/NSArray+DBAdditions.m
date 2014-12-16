#import "NSArray+DBAdditions.h"

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
