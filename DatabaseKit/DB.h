#import <Foundation/Foundation.h>

@class DBConnection, DBTable, DBCreateTableQuery;

@interface DB : NSObject
@property(readonly, strong) DBConnection *connection;

+ (DB *)withURL:(NSURL *)URL;
+ (DB *)withURL:(NSURL *)URL error:(NSError **)err;

- (id)initWithConnection:(DBConnection *)aConnection;

// Returns a table whose name matches key or nil
- (DBTable *)objectForKeyedSubscript:(id)key;

- (DBCreateTableQuery *)create;
@end
