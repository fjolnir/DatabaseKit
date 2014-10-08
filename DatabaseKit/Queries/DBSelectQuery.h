#import <DatabaseKit/DBQuery.h>

@class DBAs, DBJoin;

extern NSString *const DBInnerJoin;
extern NSString *const DBLeftJoin;

extern NSString *const DBUnion;
extern NSString *const DBUnionAll;

typedef NS_ENUM(NSUInteger, DBOrder) {
    DBOrderAscending = 1,
    DBOrderDescending
};

@interface DBSelectQuery : DBReadQuery
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

- (instancetype)order:(DBOrder)order by:(NSArray *)fields;
- (instancetype)orderBy:(NSArray *)fields;
- (instancetype)groupBy:(NSArray *)fields;
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

@interface DBAs : NSObject
@property(readonly, strong) NSString *field, *alias;

+ (DBAs *)field:(NSString *)field alias:(NSString *)alias;
@end

@interface DBQuery (DBSelectQuery)
- (DBSelectQuery *)select:(NSArray *)fields;
- (DBSelectQuery *)select;
@end
