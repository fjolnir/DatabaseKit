#import <DatabaseKit/DBQuery.h>

/*! @cond IGNORE */
@interface DBQuery () <DBTableQuery, DBFilterableQuery> {
@public
    DB *_database;
    DBTable *_table;
    NSArray *_columns;
    id _where;
}
@property(readwrite, strong) NSArray *columns;
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
@property NSArray *values;
@end
/*! @endcond */
