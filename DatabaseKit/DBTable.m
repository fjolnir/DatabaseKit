#import "DBTable.h"
#import "DBModel.h"
#import "DBQuery.h"
#import "Utilities/NSString+DBAdditions.h"

@interface DBTable ()
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
    if([DBModel namingStyle] == DBRailsNamingStyle)
        tableName = [tableName underscoredString];
    return NSClassFromString(prefix ? [prefix stringByAppendingString:tableName] : tableName);
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    return [[[[DBQuery withTable:self] select] limit:@1] where:@{ @"id": @(idx) }][0];
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    [[[DBQuery withTable:self] update:obj] where:@{ @"id": @(idx) }];
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

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[DBTable class]]
        && [_name        isEqual:[(DBTable*)object name]]
        && [_database    isEqual:[(DBTable*)object database]];
}

- (BOOL)createIndex:(NSString *)name
                 on:(id)fields
            options:(NSUInteger)options
              error:(NSError **)err
{
    NSParameterAssert([fields isKindOfClass:[NSArray class]]
                      || [fields isKindOfClass:[NSString class]]);
    NSMutableString *query = [@"CREATE " mutableCopy];
    if(options & DBKeyOptionUnique)
        [query appendString:@"UNIQUE "];
    if(options & DBCreationOptionUnlessExists)
        [query appendString:@"INDEX IF NOT EXISTS "];
    else
        [query appendString:@"INDEX "];
    [query appendString:name];
    [query appendString:@" ON "];
    [query appendString:_name];
    [query appendString:@"("];
    if([fields isKindOfClass:[NSArray class]])
        [query appendString:[fields componentsJoinedByString:@", "]];
    else
        [query appendString:fields];
    [query appendString:@")"];

    return [_database.connection executeSQL:query substitutions:nil error:err] != nil;
}

- (NSArray *)columns
{
    return [_database.connection columnsForTable:_name];
}

#pragma mark - Query generators

- (DBQuery *)select:(id)fields
{
    return [[DBQuery withTable:self] select:fields];
}
- (DBQuery *)select
{
    return [[DBQuery withTable:self] select];
}

- (DBQuery *)insert:(id)fields
{
    return [[DBQuery withTable:self] insert:fields];
}
- (DBQuery *)update:(id)fields
{
    return [[DBQuery withTable:self] update:fields];
}
- (DBQuery *)delete
{
    return [[DBQuery withTable:self] delete];
}
- (DBQuery *)where:(id)conds
{
    return [[DBQuery withTable:self] where:conds];
}
- (DBQuery *)order:(NSString *)order by:(id)fields
{
    return [[DBQuery withTable:self] order:order by:fields];
}
- (DBQuery *)orderBy:(id)fields
{
    return [[DBQuery withTable:self] orderBy:fields];
}
- (DBQuery *)limit:(NSNumber *)limit
{
    return [[DBQuery withTable:self] limit:limit];
}

@end
