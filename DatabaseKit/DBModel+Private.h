#import "DBModel.h"
#import "DB.h"

@interface DBModel ()
@property(readwrite, strong) NSString *savedIdentifier;

- (void)_clearDirtyKeys;
@end

@interface DB (DBModelUniquing)
- (NSMapTable *)liveObjectsOfModelClass:(Class)modelClass;
@end
