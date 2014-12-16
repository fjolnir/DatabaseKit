#import <Foundation/Foundation.h>

typedef id(^DBMapBlock)(id obj);
typedef BOOL(^DBFilterBlock)(id obj);

@interface NSArray (DBAdditions)
- (NSArray *)db_map:(DBMapBlock)blk;
- (NSArray *)db_filter:(DBFilterBlock)blk;
@end
