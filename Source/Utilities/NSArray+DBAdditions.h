#import <Foundation/Foundation.h>

typedef id(^DBMapBlock)(id obj);

@interface NSArray (DBAdditions)
- (NSArray *)db_map:(DBMapBlock)blk;
@end
