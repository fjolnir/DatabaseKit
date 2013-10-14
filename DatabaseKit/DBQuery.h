#import <Foundation/Foundation.h>
#import <DatabaseKit/Connections/DBConnection.h>

extern NSString *const DBSelectAll;

extern NSString *const DBOrderDescending;
extern NSString *const DBOrderAscending;

extern NSString *const DBQueryTypeSelect;
extern NSString *const DBQueryTypeInsert;
extern NSString *const DBQueryTypeUpdate;
extern NSString *const DBQueryTypeDelete;

extern NSString *const DBInnerJoin;
extern NSString *const DBLeftJoin;

extern NSString *const DBUnion;
extern NSString *const DBUnionAll;

@class DBTable;

@interface DBQuery : NSObject <NSCopying, NSFastEnumeration>
@property(readonly, strong) NSString *type;
@property(readonly, strong) DBTable *table;
@property(readonly, strong) id fields;
@property(readonly, strong) NSDictionary *where;
@property(readonly, strong) NSArray *orderedBy;
@property(readonly, strong) NSArray *groupedBy;
@property(readonly, strong) NSString *order;
@property(readonly, strong) NSNumber *limit, *offset;
@property(readonly, strong) id join;
@property(readonly, strong) DBQuery *unionQuery;
@property(readonly, strong) NSString *unionType;

+ (DBQuery *)withTable:(DBTable *)table;

- (NSArray *)execute;
- (NSArray *)execute:(NSError **)err;
- (NSArray *)executeOnConnection:(DBConnection *)connection error:(NSError **)outErr;

- (DBQuery *)select:(id)fields;
- (DBQuery *)select;
- (DBQuery *)insert:(id)fields;
- (DBQuery *)update:(id)fields;
- (DBQuery *)delete;
- (DBQuery *)where:(id)conds;
- (DBQuery *)appendWhere:(id)conds;
- (DBQuery *)order:(NSString *)order by:(id)fields;
- (DBQuery *)orderBy:(id)fields;
- (DBQuery *)groupBy:(id)fields;
- (DBQuery *)limit:(NSNumber *)limit;
- (DBQuery *)offset:(NSNumber *)offset;
- (DBQuery *)join:(NSString *)type withTable:(id)table on:(NSDictionary *)fields;
- (DBQuery *)innerJoin:(id)table on:(NSDictionary *)fields;
- (DBQuery *)leftJoin:(id)table on:(NSDictionary *)fields;
- (DBQuery *)union:(DBQuery *)otherQuery;
- (DBQuery *)union:(DBQuery *)otherQuery type:(NSString *)type;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (NSUInteger)count;
- (id)first;
- (NSString *)toString;
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