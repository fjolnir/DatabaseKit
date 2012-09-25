#import <Foundation/Foundation.h>
#import <DatabaseKit/DBConnection.h>

extern NSString *const DBOrderDescending;
extern NSString *const DBOrderAscending;

extern NSString *const DBQueryTypeSelect;
extern NSString *const DBQueryTypeInsert;
extern NSString *const DBQueryTypeUpdate;
extern NSString *const DBQueryTypeDelete;

extern NSString *const DBInnerJoin;
extern NSString *const DBLeftJoin;

@interface DBQuery : NSObject <NSCopying>
@property(readonly, strong, nonatomic) DBConnection * connection;
@property(readonly, strong) NSString *type;
@property(readonly, strong) id table;
@property(readonly, strong) id fields;
@property(readonly, strong) id where;
@property(readonly, strong) NSArray *orderedBy;
@property(readonly, strong) NSString *order;
@property(readonly, strong) NSNumber *limit;
@property(readonly, strong) id join;

+ (DBQuery *)withTable:(id)table;
+ (DBQuery *)withConnection:(DBConnection *)connection table:(id)table;

- (NSArray *)execute;

- (DBQuery *)select:(id)fields;
- (DBQuery *)select;
- (DBQuery *)insert:(id)fields;
- (DBQuery *)update:(id)fields;
- (DBQuery *)delete;
- (DBQuery *)where:(id)conds;
- (DBQuery *)appendWhere:(id)conds;
- (DBQuery *)order:(NSString *)order by:(id)fields;
- (DBQuery *)orderBy:(id)fields;
- (DBQuery *)limit:(NSNumber *)limit;
- (DBQuery *)join:(NSString *)type withTable:(id)table on:(NSDictionary *)fields;
- (DBQuery *)innerJoin:(id)table on:(NSDictionary *)fields;
- (DBQuery *)leftJoin:(id)table on:(NSDictionary *)fields;

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