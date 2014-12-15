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
 * Inserts a DBModel object into the database
 *
 * @param object The object to insert.
 *         Raises NSInternalInconsistencyException if the object is nil, or already inserted into a database.
 */
- (void)insertObject:(DBModel *)object;

/*!
 * Deletes a DBModel object from the database
 *
 * @param object The object to delete.
 *         Raises NSInternalInconsistencyException if the object is not already in the database.
 */
- (void)deleteObject:(DBModel *)object;
@end
