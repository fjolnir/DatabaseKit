#import <DatabaseKit/DBModel.h>

@interface DBModel ()
@property(readwrite, strong) DB *database;
@property(readwrite, strong) NSString *savedIdentifier;
@property(readonly) NSDictionary *pendingQueries;

- (BOOL)_save:(NSError **)outErr;
@end
