#import <Foundation/Foundation.h>
#import "DBConnection.h"
#import "DBColumnDefinition.h"

@class DB, DBSelectQuery, DBInsertQuery, DBUpdateQuery, DBDeleteQuery, DBAlterTableQuery, DBDropTableQuery;

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
- (DBSelectQuery *)order:(DBOrder)order by:(id)columns;
- (DBSelectQuery *)orderBy:(id)columns;
- (DBSelectQuery *)limit:(NSUInteger)limit;

- (DBAlterTableQuery *)alter;
- (DBDropTableQuery *)drop;

- (NSUInteger)count;

- (DBType)typeOfColumn:(NSString *)column;
@end
