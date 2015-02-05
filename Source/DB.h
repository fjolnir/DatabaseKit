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
 * Saves any objects with pending changes. 
 * If a conflict occurs, `replaceExisting` determines whether or not to replace the original object.
 */
- (BOOL)saveObjectsReplacingExisting:(BOOL const)replaceExisting error:(NSError **)outErr;

/*!
 * Registers a DBModel object with the database
 *
 * @param object The object to register.
 *         Raises NSInternalInconsistencyException if the object is nil, or already registered with a database.
 */
- (void)registerObject:(DBModel *)object;
/*!
 * Registers  DBModel objects with the database
 *
 * @param aObjects The objects to register.
 *         Raises NSInternalInconsistencyException if any of the objects are nil, or already registered with a database.
 */
- (void)registerObjects:(id<NSFastEnumeration>)aObjects;

/*!
 * Remvoves a registered DBModel object from the database.
 *
 * @param object The object to remove.
 *         Raises NSInternalInconsistencyException if the object is not already in the database.
 */
- (void)removeObject:(DBModel *)object;

/*!
 * Executes `modificationBlock` on an internal serial queue, and saves any modified objects.
 */
- (BOOL)modify:(void (^)())modificationBlock error:(NSError **)outErr;


/*!
 * Executes `modificationBlock` on an internal serial queue, and saves any modified objects.
 * Raises an exception if saving fails.
 */
- (void)modify:(void (^)())modificationBlock;
@end
