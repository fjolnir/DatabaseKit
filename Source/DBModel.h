#import <Foundation/Foundation.h>

extern NSString * const kDBIdentifierColumn;

@class DB, DBQuery, DBTable, DBWriteQuery, DBResult;

/*!
 * An abstract base class for objects that should model a table.\n
 * Any keys not excluded by `+excludedKeys` will be saved to the table
 * if a column with the same name is present.
 */
@interface DBModel : NSObject <NSCopying>
@property(readonly, strong) DB *database;
@property(readwrite, copy) NSUUID *identifier;
@property(readonly, getter=isSaved) BOOL saved;
@property(readonly) BOOL hasChanges;

/*!
 * Returns the set of keys that should be saved to a database
 */
+ (NSSet *)savedKeys;
/*!
 * Returns the set of keys that should NOT be saved to a database
 * (Used by +savedKeys)
 */
+ (NSSet *)excludedKeys;

/*!
 * Returns an array of DBIndices for the model
 */
+ (NSArray *)indices;

/*!
 * Returns an array of constraints for a key
 * NOTE: Rather than overriding `constraintsForKey:`
 * you should define a method with a name like: `constraintsForMyKey`;
 * `[kls constraintsForKey:@"myKey"]` will automatically call through to it.
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
