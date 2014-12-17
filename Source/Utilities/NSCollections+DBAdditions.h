#import <Foundation/Foundation.h>

/*! @cond IGNORE */
typedef id(^DBMapBlock)(id obj);
typedef BOOL(^DBFilterBlock)(id obj);

@interface NSArray (DBAdditions)
- (NSArray *)db_map:(DBMapBlock)blk;
- (NSArray *)db_filter:(DBFilterBlock)blk;
@end

@interface NSSet (DBAdditions)
- (NSSet *)db_map:(DBMapBlock)blk;
- (NSSet *)db_filter:(DBFilterBlock)blk;
@end
/*! @endcond */
