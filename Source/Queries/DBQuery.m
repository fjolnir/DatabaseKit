#import "DBQuery+Private.h"
#import "DB.h"
#import "DBTable.h"
#import "DBModel.h"
#import "DBUtilities.h"
#import "NSPredicate+DBSQLRepresentable.h"

NSString * const DBQueryException = @"DBQueryException";

@implementation DBQuery
@synthesize table=_table;

+ (NSArray *)combineQueries:(NSArray *)aQueries
{
    if(aQueries.count <= 1)
        return aQueries;

    NSMutableArray * const result = [aQueries mutableCopy];

    NSUInteger leftIdx = 0;
    while(leftIdx < result.count) {
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
    DBNotImplemented();
    return nil;
}

+ (instancetype)withDatabase:(DB *)database
{
    DBQuery *ret = [self new];
    ret->_database = database;
    return ret;
}

+ (instancetype)withTable:(DBTable *)table
{
    DBQuery *ret = [self new];
    ret->_table  = table;
    return ret;
}

#pragma mark - Derivatives

#define IsArr(x) ([x isKindOfClass:[NSArray class]] || ([NSPointerArray class] && [x isKindOfClass:[NSPointerArray class]]))
#define IsDic(x) ([x isKindOfClass:[NSDictionary class]] || [x isKindOfClass:[NSMapTable class]])
#define IsStr(x) ([x isKindOfClass:[NSString class]])
#define IsAS(x)  ([x isKindOfClass:[DBAs class]])


- (instancetype)where:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    DBQuery *query = [self where:format arguments:args];
    va_end(args);
    return query;
}

- (instancetype)where:(NSString *)format arguments:(va_list)args
{
    return [self withPredicate:[NSPredicate predicateWithFormat:format arguments:args]];
}

- (instancetype)narrow:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSPredicate *supplementalPredicate = [NSPredicate predicateWithFormat:format arguments:args];
    va_end(args);

    return [self withPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:@[self.where, supplementalPredicate]]];
}

- (instancetype)withPredicate:(NSPredicate *)predicate
{
    if(predicate == self.where || [predicate isEqual:self.where])
        return self;
    DBQuery *ret = [self copy];
    ret.where = predicate;
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
        [query appendFormat:@"$%ld", (unsigned long)params.count];
    
    return YES;
}

- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    return NO;
}


#pragma mark -

- (DBConnection *)connection
{
    return self.database.connection;
}

- (DB *)database
{
    return _database ?: _table.database;
}
- (NSString *)stringRepresentation
{
    NSMutableString *ret = [NSMutableString new];
    [self _generateString:ret parameters:[NSMutableArray new]];
    return ret;
}

- (NSString *)description
{
    return [self stringRepresentation];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [self _copyWithSubclass:self.class];
}

- (id)_copyWithSubclass:(Class)aClass
{
    NSParameterAssert([aClass isSubclassOfClass:[DBQuery class]]);
    DBQuery *copy   = [aClass new];
    if(copy) {
        copy->_database = _database;
        copy->_table    = _table;
        copy->_columns   = _columns;
        copy->_where    = _where;
    }
    return copy;
}
@end

@implementation DBReadQuery
- (NSArray *)execute
{
    NSError *err;
    NSArray *results = [self execute:&err];
    if(!results)
        [[NSException exceptionWithName:DBQueryException
                                 reason:[NSString stringWithFormat:@"Failed to execute query '%@'", self.stringRepresentation]
                               userInfo:@{ @"error": err }] raise];
    return results;
}
- (NSArray *)execute:(NSError **)err
{
    return [self executeOnConnection:[self connection] error:err];
}
- (NSArray *)executeOnConnection:(DBConnection *)connection error:(NSError **)outErr
{
    DBNotImplemented();
    return nil;
}
@end

@implementation DBWriteQuery
- (void)execute
{
    NSError *err;
    if(![self execute:&err])
        [[NSException exceptionWithName:DBQueryException
                                 reason:[NSString stringWithFormat:@"Failed to execute query '%@'", self.stringRepresentation]
                               userInfo:@{ @"error": err }] raise];
}
- (BOOL)execute:(NSError **)err
{
    return [self executeOnConnection:[self connection] error:err];
}
- (BOOL)executeOnConnection:(DBConnection *)connection error:(NSError **)outErr
{
    NSMutableString *query = [NSMutableString new];
    NSMutableArray  *params = [NSMutableArray new];
    NSAssert([self _generateString:query parameters:params], @"Failed to generate SQL");
    return [connection executeUpdate:query substitutions:params error:outErr];
}
- (instancetype)copyWithZone:(NSZone *)zone
{
    DBWriteQuery *copy = [super copyWithZone:zone];
    copy.values = _values;
    return copy;
}
@end

@implementation DBExpression {
    NSString *_expressionString;
}

+ (instancetype)withString:(NSString *)aString
{
    DBExpression *expr = [self new];
    expr->_expressionString = [aString copy];
    return expr;
}
- (NSString *)sqlRepresentationForQuery:(DBQuery *)query
                         withParameters:(NSMutableArray *)parameters
{
    return _expressionString;
}
@end

@implementation DBConnection (DBQuery)

- (BOOL)executeWriteQueriesInTransaction:(NSArray *)queries error:(NSError **)outErr
{
    switch(queries.count) {
        case 0:
            return NO;
        case 1:
            return [(DBWriteQuery *)[queries firstObject] executeOnConnection:self error:outErr];
        default:
            return [self transaction:^DBTransactionOperation{
                for(DBWriteQuery *query in queries) {
                    if(![query executeOnConnection:self error:outErr])
                        return DBTransactionRollBack;
                }
                return DBTransactionCommit;
            }];
    }
}

@end
