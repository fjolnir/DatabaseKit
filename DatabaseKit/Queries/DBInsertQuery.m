#import "DBQuery+Private.h"
#import "DBInsertQuery.h"
#import "DBSelectQuery.h"
#import "DBTable.h"
#import "DBModel.h"
#import "DBUtilities.h"

@interface DBInsertQuery ()
@property(nonatomic, readwrite) DBFallback fallback;
@end

@implementation DBInsertQuery

+ (NSString *)_queryType
{
    return @"INSERT ";
}

- (instancetype)or:(DBFallback)aFallback
{
    DBInsertQuery *query = [self copy];
    query.fallback = aFallback;
    return query;
}

- (BOOL)canCombineWithQuery:(DBQuery * const)aQuery
{
    return aQuery.class == self.class
        && DBEqual(_where, aQuery.where)
        && DBEqual(_table, aQuery.table);
}

- (instancetype)combineWith:(DBQuery * const)aQuery
{
    NSParameterAssert([self canCombineWithQuery:aQuery]);

    if([aQuery isEqual:self])
        return self;

    DBInsertQuery *query = (id)aQuery;
    DBInsertQuery *combined = [self copy];
    combined.fields = [_fields arrayByAddingObjectsFromArray:query.fields];
    combined.values = [_values arrayByAddingObjectsFromArray:query.values];
    return combined;
}

- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSParameterAssert(q && p);
    NSAssert([self.fields count] == [self.values count],
             @"Field/value count does not match");
    [q appendString:[[self class] _queryType]];

    switch(_fallback) {
        case DBInsertFallbackReplace:
            [q appendString:@"OR REPLACE "];
            break;
        case DBInsertFallbackAbort:
            [q appendString:@"OR ABORT "];
            break;
            case DBInsertFallbackFail:
            [q appendString:@"OR FAIL "];
            break;
            case DBInsertFallbackIgnore:
            [q appendString:@"OR IGNORE "];
            break;
        default: break;
    }

    [q appendString:@"INTO "];
    [q appendString:[_table toString]];
    [q appendString:@"(\""];
    [q appendString:[_fields componentsJoinedByString:@"\", \""]];
    [q appendString:@"\") VALUES("];
    int i = 0;
    for(id value in _values) {
        if(__builtin_expect(i++ > 0, 1))
            [q appendString:@", "];

        [p addObject:value ?: [NSNull null]];
        [q appendFormat:@"$%lu", (unsigned long)[p count]];
    }
    [q appendString:@")"];

    return YES;
}

@end

@implementation DBUpdateQuery

+ (NSString *)_queryType
{
    return @"UPDATE ";
}

- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSAssert([self.fields count] == [self.values count],
             @"Field/value count does not match");

    [q appendString:[[self class] _queryType]];

    [q appendString:[_table toString]];
    [q appendString:@" SET \""];

    for(NSUInteger i = 0; i < [_fields count]; ++i) {
        if(__builtin_expect(i++ > 0, 1))
            [q appendString:@", \""];
        [q appendString:_fields[i]];
        [q appendString:@"\"="];
        id obj = _values[i];
        if([obj isEqual:[NSNull null]])
            [q appendString:@"NULL"];
        else if([obj isKindOfClass:[DBExpression class]]) {
            [q appendString:@"("];
            [q appendString:[obj toString]];
            [q appendString:@")"];
        } else
            [self _addParam:obj withToken:YES currentParams:p query:q];
    }

    return [self _generateWhereString:q parameters:p];
}

@end


@implementation DBQuery (DBInsertQuery)

- (DBInsertQuery *)insert:(NSDictionary *)pairs
{
    DBInsertQuery *ret = [self _copyWithSubclass:[DBInsertQuery class]];
    ret.fields = [pairs allKeys];
    ret.values = [pairs objectsForKeys:ret.fields notFoundMarker:[NSNull null]];
    return ret;
}

@end

@implementation DBQuery (DBUpdateQuery)

- (DBUpdateQuery *)update:(NSDictionary *)pairs
{
    DBUpdateQuery *ret = [self _copyWithSubclass:[DBUpdateQuery class]];
    ret.fields = [pairs allKeys];
    ret.values = [pairs objectsForKeys:ret.fields notFoundMarker:[NSNull null]];
    return ret;
}

@end