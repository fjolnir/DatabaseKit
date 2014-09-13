#import <DatabaseKit/Queries/DBQuery.h>

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
@property(readonly, strong) NSNumber *limit, *offset;
@property(readonly, strong) id join;
@property(readonly, strong) DBSelectQuery *unionQuery;
@property(readonly, strong) NSString *unionType;

- (instancetype)order:(NSString *)order by:(NSArray *)fields;
- (instancetype)orderBy:(NSArray *)fields;
- (instancetype)groupBy:(NSArray *)fields;
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
