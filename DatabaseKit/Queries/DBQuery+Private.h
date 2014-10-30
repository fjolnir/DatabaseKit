#import "DBQuery.h"

@interface DBQuery () <DBTableQuery, DBFilterableQuery> {
@protected
    DB *_database;
    DBTable *_table;
    NSArray *_fields;
    id _where;
}
@property(readwrite, strong) NSArray *fields;
@property(readwrite, strong) NSPredicate *where;

- (BOOL)_generateString:(NSMutableString *)query parameters:(NSMutableArray *)parameters;
- (BOOL)_addParam:(id)param
        withToken:(BOOL)addToken
    currentParams:(NSMutableArray *)params
            query:(NSMutableString *)query;

- (id)_copyWithSubclass:(Class)aClass;
@end

@interface DBWriteQuery () {
@protected
    NSArray *_values;
}
@property(nonatomic, readwrite) NSArray *values;
@end