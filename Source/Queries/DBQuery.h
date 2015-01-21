#import <Foundation/Foundation.h>
#import <DatabaseKit/DBConnection.h>
#import <DatabaseKit/DBSQLRepresentable.h>

@class DBTable, DB;

extern NSString * const DBQueryException;

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
@property(readonly, strong) NSArray *columns;

+ (instancetype)withDatabase:(DB *)database;

+ (NSArray *)combineQueries:(NSArray *)aQueries;
- (BOOL)canCombineWithQuery:(DBQuery *)aQuery;
- (instancetype)combineWith:(DBQuery *)aQuery;

- (DBResult *)rawExecuteOnConnection:(DBConnection *)connection error:(NSError **)outErr;

- (NSString *)stringRepresentation;
@end

@interface DBReadQuery : DBQuery
- (NSArray *)execute;
- (NSArray *)execute:(NSError **)err;
- (NSArray *)executeOnConnection:(DBConnection *)connection error:(NSError **)outErr;
@end

@interface DBWriteQuery : DBQuery
@property(readonly, strong) NSArray *values;

- (void)execute;
- (BOOL)execute:(NSError **)err;
- (BOOL)executeOnConnection:(DBConnection *)connection error:(NSError **)outErr;
@end

#define DBExpr(expr) [DBExpression withString:(expr)]
@interface DBExpression : NSObject <DBSQLRepresentable>
+ (instancetype)withString:(NSString *)aString;
@end

@interface DBConnection (DBQuery)
- (BOOL)executeWriteQueriesInTransaction:(NSArray *)queries error:(NSError **)outErr;
@end
