#import "DBModel.h"

@interface DBModel ()
@property(readwrite, strong) NSString *savedIdentifier;

- (BOOL)_save:(NSError **)outErr;
@end
