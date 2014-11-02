#import "DBModel.h"

@interface DBModel ()
@property(readwrite, strong) NSString *savedIdentifier;

- (void)_clearDirtyKeys;
@end
