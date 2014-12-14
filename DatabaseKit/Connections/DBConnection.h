#import <Foundation/Foundation.h>

@class DBQuery, DBResult;

typedef NS_ENUM(NSUInteger, DBOrder) {
    DBOrderNone,
    DBOrderAscending,
    DBOrderDescending
};

typedef NS_ENUM(NSUInteger, DBType) {
    DBTypeUnknown,
    DBTypeInteger,
    DBTypeReal,
    DBTypeBoolean,
    DBTypeText,
    DBTypeBlob,
    DBTypeDate
};

typedef NS_ENUM(NSUInteger, DBResultState) {
    DBResultStateReady,
    DBResultStateNotAtEnd,
    DBResultStateAtEnd,
    DBResultStateError
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
 * Executes the given SQL query, returning a result set
 *
 * Example usage:
 * @code
 * [myConnection execute:@"SELECT *FROM mymodel WHERE id = $1"
 *            substitutions:@[@1]];
 * @endcode
 */
- (DBResult *)execute:(NSString *)sql substitutions:(id)substitutions error:(NSError **)outErr;

/*!
 * Executes the given SQL query returning whether or not it was successful.
 *
 * Example usage:
 * @code
 * [myConnection executeUpdate:@"INSERT INTO mymodel(id, name) VALUES($1, $2)"
 *            substitutions:@[@2, @"foobar"]];
 * @endcode
 */
- (BOOL)executeUpdate:(NSString *)sql substitutions:(id)substitutions error:(NSError **)outErr;

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

/*! Executes a block wrapped in a transaction */
- (BOOL)transaction:(DBTransactionBlock)aBlock;
/*! Begins a transaction (in most cases, using -transaction: is preferred) */
- (BOOL)beginTransaction;
/*! Rolls back a transaction (in most cases, using -transaction: is preferred) */
- (BOOL)rollBack;
/*! Ends a transaction (in most cases, using -transaction: is preferred) */
- (BOOL)endTransaction;

/*! Returns a SQL type string for a type */
+ (NSString *)sqlForType:(DBType)type;
/*! Inverse of `sqlForType:` */
+ (DBType)typeForSql:(NSString *)type;

/*! Returns a SQL type for a given Objective-C scalar type encoding */
+ (DBType)typeForObjCScalarEncoding:(char)encoding;
/*! Returns a SQL type for a given class*/
+ (DBType)typeForClass:(Class)klass;
@end


@interface DBResult : NSObject {
@protected
    DBResultState _state;
}
@property DBResultState state;

- (NSUInteger)indexOfColumnNamed:(NSString *)name;
- (NSArray *)toArray:(NSError **)outErr;
- (NSDictionary *)dictionaryForCurrentRow;
- (NSArray *)columns;

// Abstract:
- (DBResultState)step:(NSError **)outErr;
- (NSUInteger)columnCount;
- (NSString *)nameOfColumnAtIndex:(NSUInteger)idx;
- (id)valueOfColumnAtIndex:(NSUInteger)idx;
- (id)valueOfColumnNamed:(NSString *)columnName;
@end
