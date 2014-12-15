#import "DB.h"

@interface DB (DBModelPrivate)
- (void)registerDirtyObject:(DBModel *)obj;
@end
