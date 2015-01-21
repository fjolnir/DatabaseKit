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
#import "DBUtilities.h"

@interface DBTable ()
@property(readwrite, strong) NSString *name;
@property(readwrite, strong) DB *database;
@end

@implementation DBTable {
    NSDictionary *_columnTypes;
    Class _modelClass;
}
@synthesize columnNames=_columnNames;

+ (DBTable *)withDatabase:(DB *)database name:(NSString *)name;
{
    DBTable *ret = [self new];
    ret.database = database;
    ret.name     = name;
    if([name rangeOfString:@"."].location != NSNotFound)
        DBDebugLog(@"WARNING: table '%@'s name contains a period, this conflicts with KVC, and will likely cause issues", name);

    NSString *className = [[name db_singularizedString] db_stringByCapitalizingFirstLetter];
    NSArray *modelClasses = DBClassesInheritingFrom([DBModel class]);
    NSUInteger idx = [modelClasses indexOfObjectPassingTest:^BOOL(id klass, NSUInteger _, BOOL *__) {
        return [NSStringFromClass(klass) hasSuffix:className];
    }];
    ret->_modelClass = idx == NSNotFound ? nil : modelClasses[idx];
    return ret;
}

- (NSSet *)columnNames
{
    if(!_columnNames)
        _columnNames = [NSSet setWithArray:[[_database.connection columnsForTable:_name] allKeys]];
    return _columnNames;
}

- (DBType)typeOfColumn:(NSString *)column
{
    if(!_columnTypes)
        _columnTypes = [self.database.connection columnsForTable:self.name];
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

- (NSUInteger)numberOfRows
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
