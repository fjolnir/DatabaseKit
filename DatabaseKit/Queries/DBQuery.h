#import <Foundation/Foundation.h>
#import <DatabaseKit/Connections/DBConnection.h>

@class DBTable, DBSelectQuery, DBInsertQuery, DBUpdateQuery, DBDeleteQuery, DBRawQuery;

@interface DBQuery : NSObject <NSCopying>
@property(readonly, strong) DBTable *table;
@property(readonly, strong) id fields;
@property(readonly, strong) NSDictionary *where;

+ (instancetype)withTable:(DBTable *)table;

+ (NSArray *)combineQueries:(NSArray *)aQueries;
- (BOOL)canCombineWithQuery:(DBQuery *)aQuery;
- (instancetype)combineWith:(DBQuery *)aQuery;

- (NSArray *)execute;
- (NSArray *)execute:(NSError **)err;
- (NSArray *)executeOnConnection:(DBConnection *)connection error:(NSError **)outErr;

- (DBSelectQuery *)select:(NSArray *)fields;
- (DBSelectQuery *)select;
- (DBInsertQuery *)insert:(NSDictionary *)fields;
- (DBUpdateQuery *)update:(NSDictionary *)fields;
- (DBDeleteQuery *)delete;
- (DBRawQuery *)rawQuery:(NSString *)SQL;

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
#import <DatabaseKit/Queries/DBRawQuery.h>
