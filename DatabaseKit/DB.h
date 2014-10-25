#import <Foundation/Foundation.h>
#import <DatabaseKit/DBConnectionPool.h>

@class DBTable, DBCreateQuery;

@interface DB : NSObject
@property(readonly, strong) DBConnection *connection;

+ (DB *)withURL:(NSURL *)URL;
+ (DB *)withURL:(NSURL *)URL error:(NSError **)err;

- (id)initWithConnection:(DBConnection *)aConnection;

// Returns a table whose name matches key or nil
- (DBTable *)objectForKeyedSubscript:(id)key;

- (DBCreateQuery *)create;
@end
