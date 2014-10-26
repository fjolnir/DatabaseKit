#import <DatabaseKit/DatabaseKit.h>

@class DBSelectQuery;

@interface DBCreateQuery : DBWriteQuery
@property(readonly, nonatomic) NSString *tableName;
@property(readonly, nonatomic) NSArray *columns;
@property(readonly, nonatomic) DBSelectQuery *queryToDeriveFrom;

- (instancetype)table:(NSString *)tableName;
- (instancetype)columns:(NSArray *)columns;
- (instancetype)as:(DBSelectQuery *)queryToDeriveFrom;

- (BOOL)hasColumnNamed:(NSString *)name;
@end
