#import <Foundation/Foundation.h>
#import <ActiveRecord/ARConnection.h>

extern NSString *const AROrderDescending;
extern NSString *const AROrderAscending;

extern NSString *const ARQueryTypeSelect;
extern NSString *const ARQueryTypeInsert;
extern NSString *const ARQueryTypeUpdate;
extern NSString *const ARQueryTypeDelete;

@interface ARQuery : NSObject <NSCopying>
@property(readonly, retain, nonatomic) id<ARConnection> connection;
@property(readonly, retain) NSString *type;
@property(readonly, retain) id table;
@property(readonly, retain) id fields;
@property(readonly, retain) id where;
@property(readonly, retain) NSArray *orderedBy;
@property(readonly, retain) NSString *order;
@property(readonly, retain) NSNumber *limit;

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

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (NSString *)toString;
- (NSUInteger)count;
@end

@interface ARAs : NSObject
@property(readonly) NSString *field, *alias;

+ (ARAs *)field:(NSString *)field alias:(NSString *)alias;
- (id)initWithField:(NSString *)field alias:(NSString *)alias;
@end