#import <Foundation/Foundation.h>
#import <DatabaseKit/DBConnection.h>

@class DBTable, DB;

@protocol DBFilterableQuery
@property(readonly, strong) NSPredicate *where;

- (instancetype)where:(NSString *)format, ...;
- (instancetype)where:(id)format arguments:(va_list)args;
- (instancetype)narrow:(NSString *)format, ...;

- (instancetype)withPredicate:(NSPredicate *)predicate;
@end

@protocol DBTableQuery <NSObject>
@property(readonly, strong) DBTable *table;
+ (instancetype)withTable:(DBTable *)table;
@end

@interface DBQuery : NSObject <NSCopying>
@property(readonly, strong) DB *database;
@property(readonly, strong) NSArray *fields;

+ (instancetype)withDatabase:(DB *)database;

+ (NSArray *)combineQueries:(NSArray *)aQueries;
- (BOOL)canCombineWithQuery:(DBQuery *)aQuery;
- (instancetype)combineWith:(DBQuery *)aQuery;

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

#import <DatabaseKit/DBCreateQuery.h>
#import <DatabaseKit/DBSelectQuery.h>
#import <DatabaseKit/DBInsertQuery.h>
#import <DatabaseKit/DBDeleteQuery.h>
#import <DatabaseKit/DBAlterQuery.h>
#import <DatabaseKit/DBDropQuery.h>
