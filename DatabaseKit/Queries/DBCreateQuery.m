#import "DBQuery+Private.h"
#import "DBCreateQuery.h"

@implementation DBCreateQuery

- (instancetype)table:(NSString *)tableName
{
    DBCreateQuery *query = [self copy];
    query->_tableName = tableName;
    return query;
}

- (instancetype)columns:(NSArray *)columns
{
    DBCreateQuery *query = [self copy];
    query->_queryToDeriveFrom = nil;
    query->_columns = columns;
    return query;
}
- (instancetype)as:(DBSelectQuery *)queryToDeriveFrom
{
    DBCreateQuery *query = [self copy];
    query->_columns = nil;
    query->_queryToDeriveFrom = queryToDeriveFrom;
    return query;
}

- (BOOL)hasColumnNamed:(NSString *)name
{
    if(!_columns)
        return NO;
    else
        return [_columns indexOfObjectPassingTest:^BOOL(DBColumn *col, NSUInteger idx, BOOL *stop) {
            return [name isEqualToString:col.name];
        }] != NSNotFound;
}

- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSParameterAssert(q && p);
    if(!_tableName || (!_columns && !_queryToDeriveFrom))
        return NO;

    [q appendString:@"CREATE TABLE `"];
    [q appendString:_tableName];
    [q appendString:@"`"];
    
    if(_columns) {
        [q appendString:@"("];
        for(NSUInteger i = 0; i < [_columns count]; ++i) {
            if(i > 0)
                [q appendString:@", "];
            [q appendString:[_columns[i] sqlRepresentationForQuery:self withParameters:p]];
        }
        [q appendString:@")"];
    } else if(_queryToDeriveFrom) {
        [q appendString:@" AS ("];
        if(![_queryToDeriveFrom _generateString:q parameters:p])
            return NO;
        [q appendString:@")"];
    }
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    DBCreateQuery *copy   = [super copyWithZone:zone];
    copy->_tableName = _tableName;
    copy->_columns   = _columns;
    return copy;
}

@end

