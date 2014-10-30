#import <Foundation/Foundation.h>
#import <DatabaseKit/DB.h>
#import <DatabaseKit/DBConnection.h>

static NSString * const kDBIdentifierColumn = @"identifier";

@class DBTable;

/*!
 * The abstract base class for the DatabaseKit implementation\n
 * All models are subclasses of DBModel\n
 * \n
 * To use DBModel, subclass it with a class named <prefix>ModelName
 * set the prefix you'll use in +load (along with the default connection if you want one)\n
 * DBModel will then determine the table name (<prefix>ModelName -> modelname)\n
 */
@interface DBModel : NSObject <NSCopying>
@property(readonly, strong) DBTable *table;
@property(readwrite, copy) NSString *identifier;
@property(readonly, getter=isInserted) BOOL inserted;
@property(readonly, retain) NSSet *dirtyKeys;

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

/*! Returns a model object in the given database
 *  You must set an identifier before saving
 */
- (id)initWithDatabase:(DB *)aDB;

/*! Sets the class prefix for models\n
 * Example: You have a project called TestApp, and therefore all your classes have a TA prefix.\n
 * Suddenly calling your models simply MyModel, would be inconsistent so you set the prefix to "TA" and now calling the model TAMyModel will work
 */
+ (void)setClassPrefix:(NSString *)aPrefix;
/*! Returns the class prefix for models */
+ (NSString *)classPrefix;

/*!
 * Returns the type of a key (along with the class if it is '@')
 */
+ (char)typeForKey:(NSString *)key class:(Class *)outClass;

/*!
 * Returns an array of constraints for a key
 */
+ (NSArray *)constraintsForKey:(NSString *)key;

/*! Saves changes to the database
 */
- (BOOL)save:(NSError **)outErr;
- (BOOL)save;

/*! Deletes a record from the database
 */
- (BOOL)destroy;

/*! Returns the table name of the record based on the class name by converting it to lowercase, pluralizing it and removing the class prefix if one is set. */
+ (NSString *)tableName;

/*! Creates a query with a WHERE clause specifying the record */
- (DBQuery *)query;

@end
