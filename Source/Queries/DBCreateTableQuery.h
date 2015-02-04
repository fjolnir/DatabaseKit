#import <DatabaseKit/DBQuery.h>

@class DBSelectQuery;

@interface DBCreateTableQuery : DBWriteQuery
@property(readonly) NSString *tableName;
@property(readonly) NSArray *columns, *constraints;;
@property(readonly) DBSelectQuery *queryToDeriveFrom;

- (instancetype)table:(NSString *)tableName;
- (instancetype)columns:(NSArray *)columns;
- (instancetype)constraints:(NSArray *)constraints;
- (instancetype)as:(DBSelectQuery *)queryToDeriveFrom;

- (BOOL)hasColumnNamed:(NSString *)name;
@end
