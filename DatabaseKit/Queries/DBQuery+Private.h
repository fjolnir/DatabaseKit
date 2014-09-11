#import "DBQuery.h"

@interface DBQuery () {
@protected
    DBTable *_table;
    id _fields;
    NSDictionary *_where;

    BOOL _dirty;
    NSArray *_rows;
}
@property(readwrite, strong) DBTable *table;
@property(readwrite, strong) id fields;
@property(readwrite, strong) NSDictionary *where;

+ (NSString *)_queryType;

- (BOOL)_generateString:(NSMutableString *)query parameters:(NSMutableArray *)parameters;
- (BOOL)_generateWhereString:(NSMutableString *)query parameters:(NSMutableArray *)parameters;
- (BOOL)_addParam:(id)param
        withToken:(BOOL)addToken
    currentParams:(NSMutableArray *)params
            query:(NSMutableString *)query;

- (id)_copyWithSubclass:(Class)aClass;
@end