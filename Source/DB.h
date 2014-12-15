#import <Foundation/Foundation.h>

@class DBConnection, DBTable, DBCreateTableQuery;

@interface DB : NSObject
@property(readonly, strong) DBConnection *connection;

+ (DB *)withURL:(NSURL *)URL;
+ (DB *)withURL:(NSURL *)URL error:(NSError **)err;

- (id)initWithConnection:(DBConnection *)aConnection;

/*!
 * Returns a table whose name matches key or nil if it doesn't exist
 */
- (DBTable *)objectForKeyedSubscript:(id)key;

/*!
 * Returns a `CREATE TABLE` query
 */
- (DBCreateTableQuery *)create;
@end

@class DBModel;
@interface DB (DBModel)
/*!
 * Saves any objects with pending changes.
 */
- (BOOL)save:(NSError **)outErr;
@end
