#import <Foundation/Foundation.h>
#import <DatabaseKit/Connections/DBConnection.h>
#import <DatabaseKit/Utilities/DBIndexedCollection.h>

extern NSString *const DBSelectAll;

extern NSString *const DBOrderDescending;
extern NSString *const DBOrderAscending;

extern NSString *const DBInnerJoin;
extern NSString *const DBLeftJoin;

extern NSString *const DBUnion;
extern NSString *const DBUnionAll;

@class DBTable, DBSelectQuery, DBInsertQuery, DBUpdateQuery, DBDeleteQuery;

@interface DBQuery : NSObject <NSCopying>
//@property(readonly, strong) NSString *type;
@property(readonly, strong) DBTable *table;
@property(readonly, strong) id fields;
@property(readonly, strong) NSDictionary *where;

+ (instancetype)withTable:(DBTable *)table;

- (NSArray *)execute;
- (NSArray *)execute:(NSError **)err;
- (NSArray *)executeOnConnection:(DBConnection *)connection error:(NSError **)outErr;

- (DBSelectQuery *)select:(id<DBIndexedCollection>)fields;
- (DBSelectQuery *)select;
- (DBInsertQuery *)insert:(id<DBKeyedCollection>)fields;
- (DBUpdateQuery *)update:(id<DBKeyedCollection>)fields;
- (DBDeleteQuery *)delete;

- (instancetype)where:(id)conds;
- (instancetype)appendWhere:(id)conds;

- (NSString *)toString;
@end

@interface DBSelectQuery : DBQuery <NSFastEnumeration>
@property(readonly, strong) NSArray *orderedBy;
@property(readonly, strong) NSArray *groupedBy;
@property(readonly, strong) NSString *order;
@property(readonly, strong) NSNumber *limit, *offset;
@property(readonly, strong) id join;
@property(readonly, strong) DBSelectQuery *unionQuery;
@property(readonly, strong) NSString *unionType;

- (instancetype)order:(NSString *)order by:(id)fields;
- (instancetype)orderBy:(id)fields;
- (instancetype)groupBy:(id)fields;
- (instancetype)limit:(NSNumber *)limit;
- (instancetype)offset:(NSNumber *)offset;

- (instancetype)join:(NSString *)type withTable:(id)table on:(NSDictionary *)fields;
- (instancetype)innerJoin:(id)table on:(NSDictionary *)fields;
- (instancetype)leftJoin:(id)table on:(NSDictionary *)fields;
- (instancetype)union:(DBSelectQuery *)otherQuery;
- (instancetype)union:(DBSelectQuery *)otherQuery type:(NSString *)type;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (NSUInteger)count;
- (id)first;
@end

@interface DBInsertQuery : DBQuery
@end

@interface DBUpdateQuery : DBInsertQuery
@end

@interface DBDeleteQuery : DBQuery
@end

@interface DBJoin : NSObject
@property(readonly, strong) NSString *type;
@property(readonly, strong) id table;
@property(readonly, strong) NSDictionary *fields;
+ (DBJoin *)withType:(NSString *)type table:(id)table fields:(NSDictionary *)fields;
@end

@interface DBAs : NSObject
@property(readonly, strong) NSString *field, *alias;

+ (DBAs *)field:(NSString *)field alias:(NSString *)alias;
@end