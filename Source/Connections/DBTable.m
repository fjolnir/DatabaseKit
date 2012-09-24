#import "DBTable.h"
#import "DBBase.h"
#import "DBQuery.h"
#import "NSString+DBAdditions.h"

@interface DBTable ()
@property(readwrite, strong) NSString *name;
@property(readwrite, strong) id<DBConnection> connection;
@end

@implementation DBTable

+ (DBTable *)withName:(NSString *)name
{
    return [self withConnection:nil name:name];
}

+ (DBTable *)withConnection:(id<DBConnection>)connection name:(NSString *)name
{
    DBTable *ret   = [self new];
    ret.connection = connection;
    ret.name       = name;
    return ret;
}

- (Class)modelClass
{
    NSString *prefix    = [DBBase classPrefix];
    NSString *tableName = [[_name singularizedString] capitalizedString];
    return NSClassFromString(prefix ? [prefix stringByAppendingString:tableName] : tableName);
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    return [[[[DBQuery withConnection:_connection table:self] select] limit:@1] where:@{ @"id": @(idx) }][idx];
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    [[[DBQuery withConnection:_connection table:self] update:obj] where:@{ @"id": @(idx) }];
}

- (id)objectAtKeyedSubscript:(id)cond
{
    return [[[[DBQuery withConnection:_connection table:self] select] limit:@1] where:cond][0];
}

- (void)setObject:(id)obj atKeyedSubscript:(id)cond
{
    [[[DBQuery withConnection:_connection table:self] update:obj] where:cond];
}

- (NSString *)toString
{
    return _name;
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[DBTable class]]
        && [_name        isEqual:[(DBTable*)object name]]
        && [_connection  isEqual:[(DBTable*)object connection]];
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
