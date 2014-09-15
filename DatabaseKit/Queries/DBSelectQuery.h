#import <DatabaseKit/DBQuery.h>

extern NSString *const DBSelectAll;

extern NSString *const DBOrderDescending;
extern NSString *const DBOrderAscending;

extern NSString *const DBInnerJoin;
extern NSString *const DBLeftJoin;

extern NSString *const DBUnion;
extern NSString *const DBUnionAll;

@interface DBSelectQuery : DBQuery <NSFastEnumeration>
@property(readonly, strong) NSArray *orderedBy;
@property(readonly, strong) NSArray *groupedBy;
@property(readonly, strong) NSString *order;
@property(readonly)         NSUInteger limit, offset;
@property(readonly, strong) id join;
@property(readonly, strong) DBSelectQuery *unionQuery;
@property(readonly, strong) NSString *unionType;

- (instancetype)order:(NSString *)order by:(NSArray *)fields;
- (instancetype)orderBy:(NSArray *)fields;
- (instancetype)groupBy:(NSArray *)fields;
- (instancetype)limit:(NSUInteger)limit;
- (instancetype)offset:(NSUInteger)offset;

- (instancetype)join:(NSString *)type withTable:(id)table on:(NSDictionary *)fields;
- (instancetype)innerJoin:(id)table on:(NSDictionary *)fields;
- (instancetype)leftJoin:(id)table on:(NSDictionary *)fields;
- (instancetype)union:(DBSelectQuery *)otherQuery;
- (instancetype)union:(DBSelectQuery *)otherQuery type:(NSString *)type;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (NSUInteger)count;
- (id)firstObject;
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
