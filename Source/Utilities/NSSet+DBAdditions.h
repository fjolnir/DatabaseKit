#import <Foundation/Foundation.h>
#import "NSArray+DBAdditions.h"

@interface NSSet (DBAdditions)
- (NSSet *)db_map:(DBMapBlock)blk;
- (NSSet *)db_filter:(DBFilterBlock)blk;
@end
