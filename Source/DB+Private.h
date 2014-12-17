#import <DatabaseKit/DB.h>

/*! @cond IGNORE */
@interface DB (DBModelPrivate)
- (void)registerDirtyObject:(DBModel *)obj;
@end
/*! @endcond */
