#import "DBQuery+Private.h"
#import "DBInsertQuery.h"
#import "DBSelectQuery.h"
#import "DBTable.h"
#import "DBModel.h"
#import "DBUtilities.h"
#import "NSPredicate+DBSQLRepresentable.h"

@implementation DBInsertQuery {
@public
    DBFallback _fallback;
    DBSelectQuery *_sourceQuery;
}

- (instancetype)or:(DBFallback)aFallback
{
    DBInsertQuery *query = [self copy];
    query->_fallback = aFallback;
    return query;
}

- (BOOL)canCombineWithQuery:(DBQuery * const)aQuery
{
    return aQuery.class == self.class
        && DBEqual(_table, aQuery.table);
}

- (instancetype)combineWith:(DBQuery * const)aQuery
{
    NSParameterAssert([self canCombineWithQuery:aQuery]);

    if([aQuery isEqual:self])
        return self;

    DBInsertQuery *query = (id)aQuery;
    DBInsertQuery *combined = [self copy];
    combined.columns = [_columns arrayByAddingObjectsFromArray:query.columns];
    combined.values  = [_values arrayByAddingObjectsFromArray:query.values];
    return combined;
}

- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSParameterAssert(q && p);
    NSAssert(_sourceQuery || self.columns.count == self.values.count,
             @"Field/value count does not match");
    [q appendString:@"INSERT "];

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

    [q appendString:@"INTO `"];
    [q appendString:_table.name];
    [q appendString:@"`"];
    if(_columns) {
        [q appendString:@"(\""];
        [q appendString:[_columns componentsJoinedByString:@"\", \""]];
        [q appendString:@"\")"];
    }
    if(_sourceQuery) {
        [q appendString:@" "];
        if(![_sourceQuery _generateString:q parameters:p])
            return NO;
    } else {
        [q appendString:@" VALUES("];
        int i = 0;
        for(id value in _values) {
            if(__builtin_expect(i++ > 0, 1))
                [q appendString:@", "];

            [p addObject:value ?: [NSNull null]];
            [q appendFormat:@"$%lu", (unsigned long)p.count];
        }
        [q appendString:@")"];
    }
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    DBInsertQuery *copy   = [super copyWithZone:zone];
    copy->_fallback  = _fallback;
    copy->_sourceQuery  = _sourceQuery;
    return copy;
}

@end

@implementation DBUpdateQuery

- (BOOL)canCombineWithQuery:(DBQuery * const)aQuery
{
    return [super canCombineWithQuery:aQuery]
        && DBEqual(_where, aQuery.where);
}


- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSAssert(self.columns.count == self.values.count,
             @"Field/value count does not match");

    [q appendString:@"UPDATE `"];
    [q appendString:_table.name];
    [q appendString:@"` SET `"];

    for(NSUInteger i = 0; i < _columns.count; ++i) {
        if(__builtin_expect(i > 0, 1))
            [q appendString:@", `"];
        [q appendString:_columns[i]];
        [q appendString:@"`="];
        id obj = _values[i];
        if([obj isEqual:[NSNull null]])
            [q appendString:@"NULL"];
        else if([obj isKindOfClass:[DBExpression class]]) {
            [q appendString:@"("];
            [q appendString:[obj sqlRepresentationForQuery:self withParameters:p]];
            [q appendString:@")"];
        } else
            [self _addParam:obj withToken:YES currentParams:p query:q];
    }
    if(_where) {
        [q appendString:@" WHERE "];
        [q appendString:[_where sqlRepresentationForQuery:self withParameters:p]];
    }

    return YES;
}

@end


@implementation DBQuery (DBInsertQuery)

- (DBInsertQuery *)insert:(NSDictionary *)pairs
{
    DBInsertQuery *ret = [self _copyWithSubclass:[DBInsertQuery class]];
    ret.columns = [pairs allKeys];
    ret.values = [pairs objectsForKeys:ret.columns notFoundMarker:[NSNull null]];
    return ret;
}

- (DBInsertQuery *)insertUsingSelect:(DBSelectQuery *)sourceQuery intoColumns:(NSArray *)columns
{
    DBInsertQuery *ret = [self _copyWithSubclass:[DBInsertQuery class]];
    ret->_sourceQuery = sourceQuery;
    ret->_columns = columns;
    return ret;
}
- (DBInsertQuery *)insertUsingSelect:(DBSelectQuery *)sourceQuery
{
    return [self insertUsingSelect:sourceQuery intoColumns:sourceQuery.columns];
}
@end

@implementation DBQuery (DBUpdateQuery)

- (DBUpdateQuery *)update:(NSDictionary *)pairs
{
    DBUpdateQuery *ret = [self _copyWithSubclass:[DBUpdateQuery class]];
    ret.columns = [pairs allKeys];
    ret.values = [pairs objectsForKeys:ret.columns notFoundMarker:[NSNull null]];
    return ret;
}

@end
