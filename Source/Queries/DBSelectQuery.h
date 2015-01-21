#import <DatabaseKit/DBQuery.h>
#import <DatabaseKit/DBModel.h>

@class DBAs, DBJoin;

extern NSString *const DBInnerJoin;
extern NSString *const DBLeftJoin;

extern NSString *const DBUnion;
extern NSString *const DBUnionAll;

@interface DBSelectQuery : DBReadQuery <DBTableQuery, DBFilterableQuery, NSFastEnumeration>
@property(readonly, strong) DBSelectQuery *subQuery;
@property(readonly, strong) NSArray *orderedBy;
@property(readonly, strong) NSArray *groupedBy;
@property(readonly)         DBOrder order;
@property(readonly)         NSUInteger limit, offset;
@property(readonly, strong) DBJoin *join;
@property(readonly, strong) DBSelectQuery *unionQuery;
@property(readonly, strong) NSString *unionType;
@property(readonly)         BOOL distinct;

+ (instancetype)fromSubquery:(DBSelectQuery *)aSubQuery;

- (instancetype)order:(DBOrder)order by:(NSArray *)columns;
- (instancetype)orderBy:(NSArray *)columns;
- (instancetype)groupBy:(NSArray *)columns;
- (instancetype)limit:(NSUInteger)limit;
- (instancetype)offset:(NSUInteger)offset;
- (instancetype)distinct:(BOOL)distinct;

- (instancetype)join:(DBJoin *)join;
- (instancetype)innerJoin:(id)table on:(NSString *)format, ...;
- (instancetype)leftJoin:(id)table on:(NSString *)format, ...;
- (instancetype)union:(DBSelectQuery *)otherQuery;
- (instancetype)union:(DBSelectQuery *)otherQuery type:(NSString *)type;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (NSUInteger)count;
- (id)firstObject;
@end

@interface DBJoin : NSObject
@property(readonly, strong) NSString *type;
@property(readonly, strong) DBTable *table;
@property(readonly, strong) NSPredicate *predicate;
+ (DBJoin *)withType:(NSString *)type table:(id)table predicate:(NSPredicate *)aPredicate;
@end

@interface DBAs : NSObject <DBSQLRepresentable>
@property(readonly, strong) NSString *field, *alias;

+ (DBAs *)field:(NSString *)field alias:(NSString *)alias;
@end

@interface DBQuery (DBSelectQuery)
- (DBSelectQuery *)select:(NSArray *)columns;
- (DBSelectQuery *)select;
@end

@interface DBModel (DBSelectQuery)
+ (BOOL)shouldBeUsedForResults;
@end
