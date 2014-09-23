#import <Foundation/Foundation.h>
#import <DatabaseKit/DBConnection.h>

@class DBTable;


@interface DBQuery : NSObject <NSCopying>
@property(readonly, strong) DBTable *table;
@property(readonly, strong) NSArray *fields;
@property(readonly, strong) id where;

+ (instancetype)withTable:(DBTable *)table;

+ (NSArray *)combineQueries:(NSArray *)aQueries;
- (BOOL)canCombineWithQuery:(DBQuery *)aQuery;
- (instancetype)combineWith:(DBQuery *)aQuery;

- (instancetype)where:(id)conds, ...;
- (instancetype)where:(id)conds arguments:(va_list)args;

- (NSString *)toString;
@end

@interface DBReadQuery : DBQuery
- (NSArray *)execute;
- (NSArray *)execute:(NSError **)err;
- (NSArray *)executeOnConnection:(DBConnection *)connection error:(NSError **)outErr;
@end

@interface DBWriteQuery : DBQuery
@property(readonly, strong) NSArray *values;

- (BOOL)execute;
- (BOOL)execute:(NSError **)err;
- (BOOL)executeOnConnection:(DBConnection *)connection error:(NSError **)outErr;
@end

#define DBExpr(expr) [DBExpression withString:(expr)]
@interface DBExpression : NSObject
+ (instancetype)withString:(NSString *)aString;
- (NSString *)toString;
@end

#import <DatabaseKit/DBSelectQuery.h>
#import <DatabaseKit/DBInsertQuery.h>
#import <DatabaseKit/DBDeleteQuery.h>
