#import <Foundation/Foundation.h>

extern NSString * const kDBIdentifierColumn;

@class DB, DBQuery, DBTable, DBWriteQuery, DBResult;

/*!
 * The abstract base class for the DatabaseKit implementation\n
 * All models are subclasses of DBModel\n
 * \n
 * To use DBModel, subclass it with a class named <prefix>ModelName
 * set the prefix you'll use in +load (along with the default connection if you want one)\n
 * DBModel will then determine the table name (<prefix>ModelName -> modelname)\n
 */
@interface DBModel : NSObject <NSCopying>
@property(readonly, strong) DB *database;
@property(readwrite, copy) NSString *identifier;
@property(readonly, getter=isSaved) BOOL saved;
@property(readonly) BOOL hasChanges;

/*!
 * Returns the set of keys that should be saved to the database
 */
+ (NSSet *)savedKeys;
/*!
 * Returns the set of keys that should NOT be saved to the database
 * (Used by +savedKeys)
 */
+ (NSSet *)excludedKeys;

/*!
 * Returns an array of DBIndices for the model
 */
+ (NSArray *)indices;

/*! Returns a model object registered with the given database
 */
- (instancetype)initWithDatabase:(DB *)aDB;

/*!
 * Returns an array of constraints for a key
 * NOTE: Rather than overriding `constraintsForKey:`
 * you should define a method with a name like: `constraintsForMyKey`, `[kls constraintsForKey:@"myKey"]` will automatically call through to it.
 */
+ (NSArray *)constraintsForKey:(NSString *)key;

/*!
 * Returns a query to use to save a given key to the database.
 */
- (DBWriteQuery *)saveQueryForKey:(NSString *)key;

/*! Returns the table name of the record based on the class name by converting it to lowercase, pluralizing it and removing the class prefix if one is set. */
+ (NSString *)tableName;

/*! Creates a query with a WHERE clause specifying the record */
- (DBQuery *)query;

@end
