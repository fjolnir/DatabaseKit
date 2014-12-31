#import <DatabaseKit/DBModel.h>

/*! @cond IGNORE */
@interface DBModel ()
@property(readwrite, strong) DB *database;
@property(readwrite, strong) NSString *savedIdentifier;
@property(readonly) NSDictionary *pendingQueries;

- (instancetype)initWithDatabase:(DB *)aDB result:(DBResult *)result;
- (BOOL)_executePendingQueries:(NSError **)outErr;
@end
/*! @endcond */
