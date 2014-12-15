#import <Foundation/Foundation.h>
@class DBConnection;

@interface DBConnectionProxy : NSProxy
@property(readonly) NSURL *connectionURL;
@property(readonly, copy) DBConnection *connection;

+ (id)connectionProxyWithURL:(NSURL *)URL error:(NSError **)err;
- (DBConnection *)connection:(NSError **)outErr;
@end
