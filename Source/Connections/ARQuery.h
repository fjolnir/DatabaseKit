#import <Foundation/Foundation.h>
#import <ActiveRecord/ARConnection.h>

extern NSString *const AROrderDescending;
extern NSString *const AROrderAscending;

extern NSString *const ARQueryTypeSelect;
extern NSString *const ARQueryTypeInsert;
extern NSString *const ARQueryTypeUpdate;
extern NSString *const ARQueryTypeDelete;

extern NSString *const ARInnerJoin;
extern NSString *const ARLeftJoin;

@interface ARQuery : NSObject <NSCopying>
@property(readonly, strong, nonatomic) id<ARConnection> connection;
@property(readonly, strong) NSString *type;
@property(readonly, strong) id table;
@property(readonly, strong) id fields;
@property(readonly, strong) id where;
@property(readonly, strong) NSArray *orderedBy;
@property(readonly, strong) NSString *order;
@property(readonly, strong) NSNumber *limit;
@property(readonly, strong) id join;

+ (ARQuery *)withTable:(id)table;
+ (ARQuery *)withConnection:(id<ARConnection>)connection table:(id)table;

- (NSArray *)execute;

- (ARQuery *)select:(id)fields;
- (ARQuery *)select;
- (ARQuery *)insert:(id)fields;
- (ARQuery *)update:(id)fields;
- (ARQuery *)delete;
- (ARQuery *)where:(id)conds;
- (ARQuery *)appendWhere:(id)conds;
- (ARQuery *)order:(NSString *)order by:(id)fields;
- (ARQuery *)orderBy:(id)fields;
- (ARQuery *)limit:(NSNumber *)limit;
- (ARQuery *)join:(NSString *)type withTable:(id)table on:(NSDictionary *)fields;
- (ARQuery *)innerJoin:(id)table on:(NSDictionary *)fields;
- (ARQuery *)leftJoin:(id)table on:(NSDictionary *)fields;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (NSString *)toString;
- (NSUInteger)count;
@end

@interface ARJoin : NSObject
@property(readonly, strong) NSString *type;
@property(readonly, strong) id table;
@property(readonly, strong) NSDictionary *fields;
+ (ARJoin *)withType:(NSString *)type table:(id)table fields:(NSDictionary *)fields;
@end

@interface ARAs : NSObject
@property(readonly, strong) NSString *field, *alias;

+ (ARAs *)field:(NSString *)field alias:(NSString *)alias;
@end