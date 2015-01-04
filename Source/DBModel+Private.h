#import <DatabaseKit/DBModel.h>

/*! @cond IGNORE */
@interface DBModel ()
@property(readwrite, strong) DB *database;
@property(readwrite, strong) NSUUID *savedUUID;
@property(readonly) NSDictionary *pendingQueries;

+ (NSString *)joinTableNameForKey:(NSString *)key;

- (instancetype)initWithDatabase:(DB *)aDB result:(DBResult *)result;
- (BOOL)_executePendingQueries:(NSError **)outErr;
@end
/*! @endcond */
