#import <DatabaseKit/DB.h>

/*! @cond IGNORE */
@interface DB (DBModelPrivate)
- (void)registerDirtyObject:(DBModel *)obj;
- (DBModel *)objectWithUUID:(NSUUID *)UUID ofModelClass:(Class)aClass;
@end
/*! @endcond */
