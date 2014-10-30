#import <Foundation/Foundation.h>
#import <DatabaseKit/DB.h>

#import <DatabaseKit/DBQuery.h>
#import <DatabaseKit/DBColumnDefinition.h>

@class DBSelectQuery, DBInsertQuery, DBUpdateQuery, DBDeleteQuery, DBAlterQuery, DBDropQuery;

typedef NS_ENUM(NSUInteger, DBColumnType) {
    DBColumnTypeInvalid,
    DBColumnTypeUnknown,
    DBColumnTypeInteger,
    DBColumnTypeFloat,
    DBColumnTypeText,
    DBColumnTypeBlob,
    DBColumnTypeDate
};

@interface DBTable : NSObject
@property(readonly, strong) NSString *name;
@property(readonly, strong) DB *database;
@property(readonly, strong) NSSet *columns;

+ (DBTable *)withDatabase:(DB *)database name:(NSString *)name;

- (NSString *)toString;
- (Class)modelClass;

- (id)objectForKeyedSubscript:(id)cond;
- (void)setObject:(id)obj forKeyedSubscript:(id)cond;

- (DBSelectQuery *)select:(NSArray *)columns;
- (DBSelectQuery *)select;
- (DBInsertQuery *)insert:(NSDictionary *)columns;
- (DBInsertQuery *)insertUsingSelect:(DBSelectQuery *)sourceQuery;
- (DBInsertQuery *)insertUsingSelect:(DBSelectQuery *)sourceQuery intoColumns:(NSArray *)columns;
- (DBUpdateQuery *)update:(NSDictionary *)columns;
- (DBDeleteQuery *)delete;
- (DBSelectQuery *)where:(id)conds, ...;
- (DBSelectQuery *)order:(NSString *)order by:(id)columns;
- (DBSelectQuery *)orderBy:(id)columns;
- (DBSelectQuery *)limit:(NSUInteger)limit;

- (DBAlterQuery *)alter;
- (DBDropQuery *)drop;

- (NSUInteger)count;

- (DBColumnType)typeOfColumn:(NSString *)column;
@end
