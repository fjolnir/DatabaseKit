#import "DBQuery+Private.h"
#import "DBTable.h"
#import "DBModel.h"
#import "DBModel+Private.h"
#import "Debug.h"

NSString *const DBSelectAll = @"*";

NSString *const DBOrderDescending = @" DESC";
NSString *const DBOrderAscending  = @" ASC";

NSString *const DBInnerJoin = @" INNER ";
NSString *const DBLeftJoin  = @" LEFT ";

NSString *const DBUnion    = @" UNION ";
NSString *const DBUnionAll = @" UNION ALL ";

static NSString *const DBStringConditions = @"DBStringConditions";


@implementation DBQuery

+ (NSString *)_queryType
{
    [NSException raise:NSInternalInconsistencyException
                format:@"DBQuery does not implement SQL generation."];
    return nil;
}

+ (instancetype)withTable:(DBTable *)table
{
    DBQuery *ret = [self new];
    ret.table    = table;
    return ret;
}

#pragma mark - Derivatives

#define IsArr(x) ([x isKindOfClass:[NSArray class]] || ([NSPointerArray class] && [x isKindOfClass:[NSPointerArray class]]))
#define IsDic(x) ([x isKindOfClass:[NSDictionary class]] || [x isKindOfClass:[NSMapTable class]])
#define IsStr(x) ([x isKindOfClass:[NSString class]])
#define IsAS(x)  ([x isKindOfClass:[DBAs class]])

- (DBQuery *)select:(NSArray *)fields
{
    DBQuery *ret = [self _copyWithSubclass:[DBSelectQuery class]];
    ret.fields = !fields         ? nil
                 : IsArr(fields) ? fields
                                 : @[fields];
    return ret;
}
- (DBSelectQuery *)select
{
    return [self select:nil];
}

- (DBInsertQuery *)insert:(NSDictionary *)fields
{
    DBInsertQuery *ret = [self _copyWithSubclass:[DBInsertQuery class]];
    ret.fields = fields;
    return ret;
}
- (DBUpdateQuery *)update:(NSDictionary *)fields
{
    DBUpdateQuery *ret = [self _copyWithSubclass:[DBUpdateQuery class]];
    ret.fields = fields;
    return ret;
}
- (DBDeleteQuery *)delete
{
    DBDeleteQuery *ret = [self _copyWithSubclass:[DBDeleteQuery class]];
    ret.fields = nil;
    return ret;
}
- (instancetype)where:(id)conds
{
    NSParameterAssert(IsArr(conds) || IsDic(conds) || IsStr(conds));
    DBQuery *ret = [self copy];

    if(IsStr(conds))
        ret.where = @{ DBStringConditions: [@[@[conds]] mutableCopy] };
    else if(IsArr(conds))
        ret.where = @{ DBStringConditions: [@[conds] mutableCopy] };
    else
        ret.where = conds;
    return ret;
}
- (instancetype)appendWhere:(id)conds
{
    if(!_where)
        return [self where:conds];
    BOOL isStr = IsStr(conds);
    NSParameterAssert(IsArr(conds) || IsDic(conds) || isStr);
    DBQuery *ret = [self copy];

    NSMutableDictionary *derivedConds = [_where mutableCopy];
    derivedConds[DBStringConditions] = [_where[DBStringConditions] mutableCopy];
    if(isStr) {
        if(!derivedConds[DBStringConditions])
            derivedConds[DBStringConditions] = [NSMutableArray new];
        [derivedConds[DBStringConditions] addObject:@[conds]];
    } else {
        for(id key in conds) {
            derivedConds[key] = conds[key];
        }
    }
    ret.where = derivedConds;
    return ret;
}


#pragma mark -

- (BOOL)_addParam:(id)param
        withToken:(BOOL)addToken
    currentParams:(NSMutableArray *)params
            query:(NSMutableString *)query
{
    if([param isKindOfClass:[DBQuery class]]) {
        if(![param _generateString:query parameters:params])
            return NO;
        addToken = NO;
    } else if(!param)
        [params addObject:[NSNull null]];
    else
        [params addObject:param];
    if(addToken)
        [query appendFormat:@"$%ld", (unsigned long)[params count]];
    return YES;
}

- (BOOL)_generateWhereString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSParameterAssert(q && p);

    if([_where count] == 0)
        return YES;

    [q appendString:@" WHERE "];
    int i = 0;
    for(NSString *fieldName in _where) {

        if([fieldName isEqualToString:DBStringConditions]) {
            for(NSArray *cond in _where[fieldName]) {
                if(i++ > 0)
                    [q appendString:@" AND "];

                NSMutableString *condStr = [cond[0] mutableCopy];
                for(int j = 1; j < [cond count]; ++j) {
                    [self _addParam:cond[j] withToken:NO currentParams:p query:q];
                    [condStr replaceOccurrencesOfString:[NSString stringWithFormat:@"$%d", j]
                                             withString:[NSString stringWithFormat:@"$%lu", (unsigned long)[p count]]
                                                options:0
                                                  range:(NSRange){ 0, [condStr length] }];
                }
                [q appendString:@"("];
                [q appendString:condStr];
                [q appendString:@") "];
            }
        } else {
            if(i++ > 0)
                [q appendString:@" AND "];
            [q appendString:@"\""];
            [q appendString:fieldName];
            [q appendString:@"\"="];
            [self _addParam:_where[fieldName] withToken:YES currentParams:p query:q];
        }
    }
    return YES;
}

- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSParameterAssert(q && p);
    [q appendString:[[self class] _queryType]];
    return YES;
}

#pragma mark - Execution

- (NSArray *)execute
{
    NSError *err = nil;
    NSArray *result = [self executeOnConnection:[self connection] error:&err];
    if(err) {
        DBLog(@"%@", err);
        return nil;
    }
    return result;
}

- (NSArray *)execute:(NSError **)err
{
    return [self executeOnConnection:[self connection] error:err];
}

- (NSArray *)executeOnConnection:(DBConnection *)connection error:(NSError **)outErr
{
    NSError *err = nil;
    NSMutableString *query = [NSMutableString new];
    NSMutableArray  *params = [NSMutableArray new];
    NSAssert([self _generateString:query parameters:params], @"Failed to generate SQL");

    NSArray *ret = [connection executeSQL:query substitutions:params error:&err];
    if(!ret) {
        if(outErr)
            *outErr = err;
        return nil;
    }
    return ret;
}

#pragma mark -

- (DBConnection *)connection
{
    return _table.database.connection;
}

- (NSString *)toString
{
    NSMutableString *ret = [NSMutableString new];
    [self _generateString:ret parameters:[NSMutableArray new]];
    return ret;
}

- (NSString *)description
{
    return [self toString];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [self _copyWithSubclass:[self class]];
}

- (id)_copyWithSubclass:(Class)aClass
{
    NSParameterAssert([aClass isSubclassOfClass:[DBQuery class]]);
    DBQuery *copy   = [aClass new];
    copy.table      = _table;
    copy.fields     = _fields;
    copy.where      = _where;
    return copy;
}
@end

@interface DBJoin ()
@property(readwrite, strong) NSString *type;
@property(readwrite, strong) id table;
@property(readwrite, strong) NSDictionary *fields;
@end
@implementation DBJoin
+ (DBJoin *)withType:(NSString *)type table:(id)table fields:(NSDictionary *)fields
{
    NSParameterAssert([table respondsToSelector:@selector(toString)]);
    DBJoin *ret = [self new];
    ret.type   = type;
    ret.table  = table;
    ret.fields = fields;
    return ret;
}
- (NSString *)toString
{
    NSMutableString *ret = [NSMutableString stringWithString:_type];
    [ret appendString:@" JOIN "];
    [ret appendString:[_table toString]];
    [ret appendString:@" ON "];
    return ret;
}
- (NSString *)description
{
    return [self toString];
}
@end

@interface DBAs ()
@property(readwrite, strong) NSString *field, *alias;
@end
@implementation DBAs
+ (DBAs *)field:(NSString *)field alias:(NSString *)alias
{
    DBAs *ret = [self new];
    ret.field = field;
    ret.alias = alias;
    return ret;
}

- (NSString *)toString
{
    NSMutableString *ret = [NSMutableString stringWithString:_field];
    [ret appendString:@" AS "];
    [ret appendString:_alias];
    return ret;
}
- (NSString *)description
{
    return [self toString];
}
@end