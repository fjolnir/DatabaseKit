#import "DBQuery+Private.h"
#import "DBTable.h"
#import "DBModel.h"
#import "DBModel+Private.h"
#import "Debug.h"
#import "NSPredicate+DBAdditions.h"

@implementation DBQuery

+ (NSArray *)combineQueries:(NSArray *)aQueries
{
    if([aQueries count] <= 1)
        return aQueries;

    NSMutableArray * const result = [aQueries mutableCopy];

    NSUInteger leftIdx = 0;
    while(leftIdx < [result count]) {
        DBQuery * const leftQuery = result[leftIdx];
        NSUInteger const rightIdx = [result indexOfObjectPassingTest:^BOOL(DBQuery *query, NSUInteger idx, BOOL *stop) {
            return idx > leftIdx && [leftQuery canCombineWithQuery:query];
        }];

        if(rightIdx != NSNotFound) {
            DBQuery * const combined = [leftQuery combineWith:result[rightIdx]];
            [result replaceObjectAtIndex:leftIdx withObject:combined];
            [result removeObjectAtIndex:rightIdx];
        } else
            ++leftIdx;
    }
    return result;
}

- (BOOL)canCombineWithQuery:(DBQuery * const)aQuery
{
    return NO;
}

- (instancetype)combineWith:(DBQuery * const)aQuery
{
    [NSException raise:NSInternalInconsistencyException
                format:@"%@ not implemented by %@", NSStringFromSelector(_cmd), [self class]];
    return nil;
}

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
    ret.fields = fields;
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
- (DBRawQuery *)rawQuery:(NSString *)SQL
{
    DBRawQuery *ret = [self _copyWithSubclass:[DBDeleteQuery class]];
    [ret setValue:SQL forKey:@"SQL"];
    return ret;
}

- (instancetype)where:(id)conds
{
    if(conds == self.where || [conds isEqual:self.where])
        return self;
    
    NSParameterAssert(!conds || IsArr(conds) || IsDic(conds) || IsStr(conds) || [conds isKindOfClass:[NSPredicate class]]);
    DBQuery *ret = [self copy];
    ret.where = conds;
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

    if(!_where)
        return YES;
    
    [q appendString:@" WHERE "];

    if(IsStr(_where))
        [q appendString:_where];
    else if([_where isKindOfClass:[NSPredicate class]])
        [q appendString:[_where db_sqlRepresentation:p]];
    else if(IsArr(_where)) {
        NSMutableString *condStr = [_where[0] mutableCopy];
        for(int j = 1; j < [_where count]; ++j) {
            [self _addParam:_where[j] withToken:NO currentParams:p query:q];
            [condStr replaceOccurrencesOfString:[NSString stringWithFormat:@"$%d", j]
                                     withString:[NSString stringWithFormat:@"$%lu", (unsigned long)[p count]]
                                        options:0
                                          range:(NSRange){ 0, [condStr length] }];
        }
        [q appendString:@"("];
        [q appendString:condStr];
        [q appendString:@") "];
    }
    else if(IsDic(_where)) {
        int i = 0;
        for(NSString *fieldName in _where) {
            if(i++ > 0)
                [q appendString:@" AND "];
            [q appendString:@"\""];
            [q appendString:fieldName];
            [q appendString:@"\" IS "];
            [self _addParam:_where[fieldName] withToken:YES currentParams:p query:q];
        }
    } else
        return NO;
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
    } else
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

@interface DBExpression () {
    NSString *_expressionString;
}
@end

@implementation DBExpression : NSObject
+ (instancetype)withString:(NSString *)aString
{
    DBExpression *expr = [self new];
    expr->_expressionString = [aString copy];
    return expr;
}
- (NSString *)toString
{
    return _expressionString;
}
@end
