#import "DBTable.h"
#import "DBModel.h"
#import "DBQuery.h"
#import "Utilities/NSString+DBAdditions.h"

@interface DBTable ()
@property(readwrite, strong) NSString *name;
@property(readwrite, strong) DB *database;
@end

@implementation DBTable {
    NSMutableDictionary *_columnTypes;
}
@synthesize columns=_columns;

+ (DBTable *)withDatabase:(DB *)database name:(NSString *)name;
{
    DBTable *ret = [self new];
    ret.database = database;
    ret.name     = name;
    return ret;
}

- (Class)modelClass
{
    NSString *prefix    = [DBModel classPrefix];
    NSString *tableName = [[_name db_singularizedString] db_stringByCapitalizingFirstLetter];
    Class const klass = NSClassFromString(prefix ? [prefix stringByAppendingString:tableName] : tableName);
    return [klass isSubclassOfClass:[DBModel class]] ? klass : nil;
}

- (id)objectForKeyedSubscript:(id)cond
{
    return [[[DBSelectQuery withTable:self] limit:1] where:cond];
}

- (void)setObject:(id)obj forKeyedSubscript:(id)cond
{
    [[[DBUpdateQuery withTable:self] update:obj] where:cond];
}

- (NSString *)toString
{
    return _name;
}

- (NSSet *)columns
{
    if(!_columns)
        _columns = [NSSet setWithArray:[[_database.connection columnsForTable:_name] allKeys]];
    return _columns;
}

- (DBType)typeOfColumn:(NSString *)column
{
    if(!_columnTypes) {
        NSDictionary * const types = [self.database.connection columnsForTable:self.name];
        _columnTypes = [NSMutableDictionary dictionaryWithCapacity:[types count]];
        for(NSString *column in types) {
            // TODO: support more types
            NSString *type = types[column];
            if([[type lowercaseString] isEqualToString:@"text"])
                _columnTypes[column] = @(DBTypeText);
            else if([[type lowercaseString] isEqualToString:@"integer"])
                _columnTypes[column] = @(DBTypeInteger);
            else if([[type lowercaseString] isEqualToString:@"numeric"])
                _columnTypes[column] = @(DBTypeReal);
            else if([[type lowercaseString] isEqualToString:@"date"])
                _columnTypes[column] = @(DBTypeDate);
        }
    }
    return [_columnTypes[column] unsignedIntegerValue];
}

#pragma mark - Query generators

- (DBSelectQuery *)select:(NSArray *)columns
{
    return [[DBSelectQuery withTable:self] select:columns];
}
- (DBSelectQuery *)select
{
    return [DBSelectQuery withTable:self];
}

- (DBInsertQuery *)insert:(id)columns
{
    return [[DBInsertQuery withTable:self] insert:columns];
}
- (DBInsertQuery *)insertUsingSelect:(DBSelectQuery *)sourceQuery intoColumns:(NSArray *)columns
{
    return [[DBInsertQuery withTable:self] insertUsingSelect:sourceQuery intoColumns:columns];
}
- (DBInsertQuery *)insertUsingSelect:(id)sourceQuery
{
    return [[DBInsertQuery withTable:self] insertUsingSelect:sourceQuery];
}
- (DBUpdateQuery *)update:(id)columns
{
    return [[DBUpdateQuery withTable:self] update:columns];
}
- (DBDeleteQuery *)delete
{
    return [DBDeleteQuery withTable:self];
}
- (DBSelectQuery *)where:(id)conds, ...
{
    va_list args;
    va_start(args, conds);
    DBSelectQuery *query = [[DBSelectQuery withTable:self] where:conds arguments:args];
    va_end(args);
    return query;
}
- (DBQuery *)order:(DBOrder)order by:(id)columns
{
    return [[DBSelectQuery withTable:self] order:order by:columns];
}
- (DBQuery *)orderBy:(id)columns
{
    return [[DBSelectQuery withTable:self] orderBy:columns];
}
- (DBQuery *)limit:(NSUInteger)limit
{
    return [[DBSelectQuery withTable:self] limit:limit];
}

- (DBAlterTableQuery *)alter
{
    return [DBAlterTableQuery withTable:self];
}
- (DBDropTableQuery *)drop
{
    return [DBDropTableQuery withTable:self];
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
