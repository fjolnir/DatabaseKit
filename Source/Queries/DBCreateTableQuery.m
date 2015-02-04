#import "DBQuery+Private.h"
#import "DBCreateTableQuery.h"
#import "DBSelectQuery.h"
#import "DBColumnDefinition.h"
#import "NSCollections+DBAdditions.h"

@implementation DBCreateTableQuery

- (instancetype)table:(NSString *)tableName
{
    DBCreateTableQuery *query = [self copy];
    query->_tableName = tableName;
    return query;
}

- (instancetype)columns:(NSArray *)columns
{
    DBCreateTableQuery *query = [self copy];
    query->_queryToDeriveFrom = nil;
    query->_columns = columns;
    return query;
}
- (instancetype)as:(DBSelectQuery *)queryToDeriveFrom
{
    DBCreateTableQuery *query = [self copy];
    query->_columns = nil;
    query->_queryToDeriveFrom = queryToDeriveFrom;
    return query;
}
- (instancetype)constraints:(NSArray *)constraints;
{
    DBCreateTableQuery *query = [self copy];
    query->_constraints = constraints;
    return query;
}
- (BOOL)hasColumnNamed:(NSString *)name
{
    if(!_columns)
        return NO;
    else
        return [_columns indexOfObjectPassingTest:^BOOL(DBColumnDefinition *col, NSUInteger idx, BOOL *stop) {
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
    
    if(_columns.count > 0 || _constraints.count > 0) {
        [q appendString:@"("];
        [q appendString:
         [[[_columns db_map:^(DBColumnDefinition *column) {
            return [column sqlRepresentationForQuery:self withParameters:p];
         }]
         arrayByAddingObjectsFromArray:
         [_constraints db_map:^(id<DBTableConstraint> constraint) {
            return [constraint tableConstraintSQLRepresentation];
         }]] componentsJoinedByString:@", "]];
        [q appendString:@")"];
    } else if(_queryToDeriveFrom) {
        [q appendString:@" AS "];
        if(![_queryToDeriveFrom _generateString:q parameters:p])
            return NO;
    }
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    DBCreateTableQuery *copy = [super copyWithZone:zone];
    copy->_tableName   = _tableName;
    copy->_columns     = _columns;
    copy->_constraints = _constraints;
    return copy;
}

@end

