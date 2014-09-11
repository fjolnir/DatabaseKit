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

#import <DatabaseKit/Queries/DBSelectQuery.h>
#import <DatabaseKit/Queries/DBInsertQuery.h>
#import <DatabaseKit/Queries/DBDeleteQuery.h>