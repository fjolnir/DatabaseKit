#import <Foundation/Foundation.h>
#import <DatabaseKit/DB.h>

#import <DatabaseKit/DBQuery.h>
#import <DatabaseKit/DBColumn.h>

@class DBSelectQuery, DBInsertQuery, DBUpdateQuery, DBDeleteQuery;

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

- (DBSelectQuery *)select:(NSArray *)fields;
- (DBSelectQuery *)select;
- (DBInsertQuery *)insert:(NSDictionary *)fields;
- (DBUpdateQuery *)update:(NSDictionary *)fields;
- (DBDeleteQuery *)delete;
- (DBSelectQuery *)where:(id)conds, ...;
- (DBSelectQuery *)order:(NSString *)order by:(id)fields;
- (DBSelectQuery *)orderBy:(id)fields;
- (DBSelectQuery *)limit:(NSUInteger)limit;

- (NSUInteger)count;

- (DBColumnType)typeOfColumn:(NSString *)column;
@end
