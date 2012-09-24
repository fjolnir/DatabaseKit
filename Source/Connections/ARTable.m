#import "ARTable.h"
#import "ARQuery.h"

@interface ARTable ()
@property(readwrite, retain) NSString *name;
@property(readwrite, retain) id<ARConnection> connection;
@end

@implementation ARTable

+ (ARTable *)withConnection:(id<ARConnection>)connection name:(NSString *)name
{
    ARTable *ret   = [self new];
    ret.connection = connection;
    ret.name       = name;
    return [ret autorelease];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    return [[[[ARQuery withConnection:_connection table:self] select] limit:@1] where:@{ @"id": @(idx) }][idx];
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    [[[ARQuery withConnection:_connection table:self] update:obj] where:@{ @"id": @(idx) }];
}

- (id)objectAtKeyedSubscript:(id)cond
{
    return [[[[ARQuery withConnection:_connection table:self] select] limit:@1] where:cond][0];
}

- (void)setObject:(id)obj atKeyedSubscript:(id)cond
{
    [[[ARQuery withConnection:_connection table:self] update:obj] where:cond];
}

- (NSString *)toString
{
    return _name;
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[ARTable class]]
        && [_name        isEqual:[(ARTable*)object name]]
        && [_connection  isEqual:[(ARTable*)object connection]];
}

#pragma mark - Query generators

- (ARQuery *)select:(id)fields
{
    return [[ARQuery withTable:self] select:fields];
}
- (ARQuery *)select
{
    return [[ARQuery withTable:self] select];
}

- (ARQuery *)insert:(id)fields
{
    return [[ARQuery withTable:self] insert:fields];
}
- (ARQuery *)update:(id)fields
{
    return [[ARQuery withTable:self] update:fields];
}
- (ARQuery *)delete
{
    return [[ARQuery withTable:self] delete];
}
- (ARQuery *)where:(id)conds
{
    return [[ARQuery withTable:self] where:conds];
}
- (ARQuery *)order:(NSString *)order by:(id)fields
{
    return [[ARQuery withTable:self] order:order by:fields];
}
- (ARQuery *)orderBy:(id)fields
{
    return [[ARQuery withTable:self] orderBy:fields];
}
- (ARQuery *)limit:(NSNumber *)limit
{
    return [[ARQuery withTable:self] limit:limit];
}

@end
