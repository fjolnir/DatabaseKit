#import "DBTable.h"
#import "DBModel.h"
#import "DBQuery.h"
#import "Utilities/NSString+DBAdditions.h"

@interface DBTable () {
    NSArray *_columns;
}
@property(readwrite, strong) NSString *name;
@property(readwrite, strong) DB *database;
@end

@implementation DBTable

+ (DBTable *)withDatabase:(DB *)database name:(NSString *)name;
{
    DBTable *ret   = [self new];
    ret.database   = database;
    ret.name       = name;
    return ret;
}

- (Class)modelClass
{
    NSString *prefix    = [DBModel classPrefix];
    NSString *tableName = [[_name singularizedString] stringByCapitalizingFirstLetter];
    return NSClassFromString(prefix ? [prefix stringByAppendingString:tableName] : tableName);
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    return [[[[DBQuery withTable:self] select] limit:@1] where:@{ kDBIdentifierColumn: @(idx) }][0];
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    [[[DBQuery withTable:self] update:obj] where:@{ kDBIdentifierColumn: @(idx) }];
}

- (id)objectForKeyedSubscript:(id)cond
{
    return [[[[DBQuery withTable:self] select] limit:@1] where:cond];
}

- (void)setObject:(id)obj forKeyedSubscript:(id)cond
{
    [[[DBQuery withTable:self] update:obj] where:cond];
}

- (NSString *)toString
{
    return _name;
}

- (NSArray *)columns
{
    if(!_columns)
        _columns = [_database.connection columnsForTable:_name];
    return _columns;
}

#pragma mark - Query generators

- (DBSelectQuery *)select:(NSArray *)fields
{
    return [[DBQuery withTable:self] select:fields];
}
- (DBSelectQuery *)select
{
    return [[DBQuery withTable:self] select];
}

- (DBInsertQuery *)insert:(id)fields
{
    return [[DBQuery withTable:self] insert:fields];
}
- (DBUpdateQuery *)update:(id)fields
{
    return [[DBQuery withTable:self] update:fields];
}
- (DBDeleteQuery *)delete
{
    return [[DBQuery withTable:self] delete];
}
- (DBQuery *)where:(id)conds
{
    return [[DBQuery withTable:self] where:conds];
}
- (DBQuery *)order:(NSString *)order by:(id)fields
{
    return [[DBSelectQuery withTable:self] order:order by:fields];
}
- (DBQuery *)orderBy:(id)fields
{
    return [[DBSelectQuery withTable:self] orderBy:fields];
}
- (DBQuery *)limit:(NSNumber *)limit
{
    return [[DBSelectQuery withTable:self] limit:limit];
}
- (DBRawQuery *)rawQuery:(NSString *)SQL
{
    return [[DBQuery withTable:self] rawQuery:SQL];
}
- (NSUInteger)count
{
    return [[DBSelectQuery withTable:self] count];
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[DBTable class]]
        && [_name isEqual:[(DBTable*)object name]]
        && _database == [(DBTable *)object database];
}

- (NSUInteger)hash
{
    return [_name hash] ^ [_database hash];
}

@end
