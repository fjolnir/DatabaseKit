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
    NSString *tableName = [[_name singularizedString] stringByCapitalizingFirstLetter];
    Class const klass = NSClassFromString(prefix ? [prefix stringByAppendingString:tableName] : tableName);
    return [klass isSubclassOfClass:[DBModel class]] ? klass : nil;
}

- (id)objectForKeyedSubscript:(id)cond
{
    return [[[DBSelectQuery withTable:self] limit:@1] where:cond];
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

- (DBColumnType)typeOfColumn:(NSString *)column
{
    if(!_columnTypes) {
        NSDictionary * const types = [self.database.connection columnsForTable:self.name];
        _columnTypes = [NSMutableDictionary dictionaryWithCapacity:[types count]];
        for(NSString *column in types) {
            // TODO: support more types
            NSString *type = types[column];
            if([[type lowercaseString] isEqualToString:@"text"])
                _columnTypes[column] = @(DBColumnTypeText);
            else if([[type lowercaseString] isEqualToString:@"integer"])
                _columnTypes[column] = @(DBColumnTypeInteger);
            else if([[type lowercaseString] isEqualToString:@"numeric"])
                _columnTypes[column] = @(DBColumnTypeFloat);
            else if([[type lowercaseString] isEqualToString:@"date"])
                _columnTypes[column] = @(DBColumnTypeDate);
        }
    }
    return [_columnTypes[column] unsignedIntegerValue];
}

#pragma mark - Query generators

- (DBSelectQuery *)select:(NSArray *)fields
{
    return [[DBSelectQuery withTable:self] select:fields];
}
- (DBSelectQuery *)select
{
    return [DBSelectQuery withTable:self];
}

- (DBInsertQuery *)insert:(id)fields
{
    return [[DBInsertQuery withTable:self] insert:fields];
}
- (DBUpdateQuery *)update:(id)fields
{
    return [[DBUpdateQuery withTable:self] update:fields];
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
- (DBQuery *)order:(NSString *)order by:(id)fields
{
    return [[DBSelectQuery withTable:self] order:order by:fields];
}
- (DBQuery *)orderBy:(id)fields
{
    return [[DBSelectQuery withTable:self] orderBy:fields];
}
- (DBQuery *)limit:(NSUInteger)limit
{
    return [[DBSelectQuery withTable:self] limit:limit];
}

- (DBAlterQuery *)alter
{
    return [DBAlterQuery withTable:self];
}
- (DBDropQuery *)drop
{
    return [DBDropQuery withTable:self];
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
