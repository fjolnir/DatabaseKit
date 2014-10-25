#import "DBModel.h"

@interface DBModel () {
    NSMutableSet *_dirtyKeys;
}
@property(readwrite, strong) NSString *savedIdentifier;
@property(readwrite, strong) DBTable *table;

- (void)_clearDirtyKeys;
@end
