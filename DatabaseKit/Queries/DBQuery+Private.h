#import "DBQuery.h"

@interface DBQuery () {
@protected
    DBTable *_table;
    NSArray *_fields;
    id _where;
}
@property(readwrite, strong) DBTable *table;
@property(readwrite, strong) NSArray *fields;
@property(readwrite, strong) id where;

+ (NSString *)_queryType;

- (BOOL)_generateString:(NSMutableString *)query parameters:(NSMutableArray *)parameters;
- (BOOL)_generateWhereString:(NSMutableString *)query parameters:(NSMutableArray *)parameters;
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