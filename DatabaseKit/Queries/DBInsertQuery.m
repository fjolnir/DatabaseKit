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

    DBInsertQuery * const combined = [self copy];
    NSMutableDictionary *fields = [_fields mutableCopy];
    [fields addEntriesFromDictionary:aQuery.fields];
    combined.fields = fields;
    return combined;
}

- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSParameterAssert(q && p);
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
    [q appendString:[[_fields allKeys] componentsJoinedByString:@"\", \""]];
    [q appendString:@"\") VALUES("];
    int i = 0;
    for(id fieldName in _fields) {
        if(__builtin_expect(i++ > 0, 1))
            [q appendString:@", "];

        id obj = _fields[fieldName];
        [p addObject:obj ? obj : [NSNull null]];
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
    [q appendString:[[self class] _queryType]];

    [q appendString:[_table toString]];
    [q appendString:@" SET \""];
    int i = 0;
    for(id fieldName in _fields) {
        if(__builtin_expect(i++ > 0, 1))
            [q appendString:@", \""];
        [q appendString:fieldName];
        [q appendString:@"\"="];
        id obj = _fields[fieldName];
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
