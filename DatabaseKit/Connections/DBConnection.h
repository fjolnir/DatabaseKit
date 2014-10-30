#import <Foundation/Foundation.h>

@class DBQuery;

typedef NS_ENUM(NSUInteger, DBOrder) {
    DBOrderAscending = 1,
    DBOrderDescending
};

typedef NS_ENUM(NSUInteger, DBType) {
    DBTypeUnknown,
    DBTypeInteger,
    DBTypeReal,
    DBTypeBoolean,
    DBTypeText,
    DBTypeBlob
};

/*!
 * A block for executing database statements in a transaction
 * return DBTransactionRollBack to trigger a rollback
 */
typedef NS_ENUM(NSUInteger, DBTransactionOperation) {
    DBTransactionRollBack,
    DBTransactionCommit
};
typedef DBTransactionOperation (^DBTransactionBlock)();

#define DBConnectionErrorDomain @"com.databasekit.connection"

@interface DBConnection : NSObject {
    NSURL *_URL;
}
@property(readonly, retain) NSURL *URL;

/*!
 * Registers a DBConnection subclass to be tested against URLs
 */
+ (void)registerConnectionClass:(Class)kls;

/*!
 * Indicates whether or not the class can handle a URL or not
 */
+ (BOOL)canHandleURL:(NSURL *)URL;

/*!
 * Opens a connection to the database pointed to by URL
 */
+ (id)openConnectionWithURL:(NSURL *)URL error:(NSError **)err;
/*! @copydoc openConnectionWithURL:error: */
- (id)initWithURL:(NSURL *)URL error:(NSError **)err;
/*!
 * Executes the given SQL string after making substitutions(optional, pass nil if none should be made).
 * Substitutions should be used for values, not column/table names since
 * they're formatted as values
 *
 * Example usage:
 * @code
 * [myConnection executeSQL:@"INSERT INTO mymodel(id, name) VALUES(:id, :name)"
 *            substitutions:[NSDictionary dictionaryWithObjectsAndKeys:
 *                           myId, kDBIdentifierColumn,
 *                           name, @"name"]];
 * @endcode
 */
- (NSArray *)executeSQL:(NSString *)sql substitutions:(id)substitutions error:(NSError **)outErr;

/*!
 * Closes the connection\n
 * does <b>not</b> release the object object itself
 */
- (BOOL)closeConnection;
/*!
 * Returns a whether a given table exists
 * @param tableName Name of the table to check
 */
- (BOOL)tableExists:(NSString *)tableName;
/*!
 * Returns a dictionary of column types keyed by column names
 * @param tableName Name of the table to retrieve columns for
 */
- (NSDictionary *)columnsForTable:(NSString *)tableName;

/*! Begins a transaction */
- (BOOL)beginTransaction;
/*! Rolls back a transaction */
- (BOOL)rollBack;
/*! Ends a transaction */
- (BOOL)endTransaction;
/*! Executes a block wrapped in a transaction */
- (BOOL)transaction:(DBTransactionBlock)aBlock;

/*! Returns a SQL type string for a type */
+ (NSString *)sqlForType:(DBType)type;
/*! Inverse of `sqlForType:` */
+ (DBType)typeForSql:(NSString *)type;

/*! Returns a SQL type for a given Objective-C scalar type encoding */
+ (DBType)typeForObjCScalarEncoding:(char)encoding;
/*! Returns a SQL type for a given class*/
+ (DBType)typeForClass:(Class)klass;
@end
