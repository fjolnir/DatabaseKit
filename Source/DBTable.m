#import "DBTable.h"
#import "DB.h"
#import "DBModel.h"
#import "DBSelectQuery.h"
#import "DBInsertQuery.h"
#import "DBDeleteQuery.h"
#import "DBAlterTableQuery.h"
#import "DBDropTableQuery.h"
#import "NSString+DBAdditions.h"
#import "DBIntrospection.h"

@interface DBTable ()
@property(readwrite, strong) NSString *name;
@property(readwrite, strong) DB *database;
@end

@implementation DBTable {
    NSMutableDictionary *_columnTypes;
    Class _modelClass;
}
@synthesize columns=_columns;

+ (DBTable *)withDatabase:(DB *)database name:(NSString *)name;
{
    DBTable *ret = [self new];
    ret.database = database;
    ret.name     = name;

    NSString *className = [[name db_singularizedString] db_stringByCapitalizingFirstLetter];
    NSArray *modelClasses = DBClassesInheritingFrom([DBModel class]);
    NSUInteger idx = [modelClasses indexOfObjectPassingTest:^BOOL(id klass, NSUInteger _, BOOL *__) {
        return [NSStringFromClass(klass) hasSuffix:className];
    }];
    ret->_modelClass = idx == NSNotFound ? nil : modelClasses[idx];
    return ret;
}

- (id)objectForKeyedSubscript:(id)cond
{
    return [[[DBSelectQuery withTable:self] limit:1] where:cond];
}

- (void)setObject:(id)obj forKeyedSubscript:(id)cond
{
    [[[DBUpdateQuery withTable:self] update:obj] where:cond];
}

- (NSSet *)columns
{
    if(!_columns)
        _columns = [NSSet setWithArray:[[_database.connection columnsForTable:_name] allKeys]];
    return _columns;
}

- (DBType)typeOfColumn:(NSString *)column
{
    return [[self.database.connection columnsForTable:self.name][column] unsignedIntegerValue];
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
