#import <Foundation/Foundation.h>

@class DBConnection, DBTable, DBCreateTableQuery;

@interface DB : NSObject
@property(readonly, strong) DBConnection *connection;

+ (DB *)withURL:(NSURL *)URL;
+ (DB *)withURL:(NSURL *)URL error:(NSError **)err;

- (instancetype)initWithConnection:(DBConnection *)aConnection;

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
- (BOOL)saveObjects:(NSError **)outErr;

/*!
 * Registers a DBModel object with the database
 *
 * @param object The object to register.
 *         Raises NSInternalInconsistencyException if the object is nil, or already registered with a database.
 */
- (void)registerObject:(DBModel *)object;

/*!
 * Remvoves a registered DBModel object from the database.
 *
 * @param object The object to remove.
 *         Raises NSInternalInconsistencyException if the object is not already in the database.
 */
- (void)removeObject:(DBModel *)object;
@end
