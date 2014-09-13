#import "DBQuery+Private.h"
#import "DBInsertQuery.h"
#import "DBSelectQuery.h"
#import "DBTable.h"
#import "DBModel.h"
#import "DBUtilities.h"

@implementation DBInsertQuery

+ (NSString *)_queryType
{
    return @"INSERT ";
}

- (BOOL)canCombineWithQuery:(DBQuery * const)aQuery
{
    return aQuery.class == self.class
        && DBEqual(_where, aQuery.where)
        && DBEqual(_table, aQuery.table);
}

- (instancetype)combineWith:(DBQuery * const)aQuery
{
    NSParameterAssert([self canCombineWithQuery:aQuery]);

    if([aQuery isEqual:self])
        return self;

    DBInsertQuery * const combined = [self copy];
    NSMutableDictionary *fields = [_fields mutableCopy];
    [fields addEntriesFromDictionary:aQuery.fields];
    combined.fields = fields;
    return combined;
}

- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSParameterAssert(q && p);
    [q appendString:[[self class] _queryType]];

    [q appendString:@"INTO "];
    [q appendString:[_table toString]];
    [q appendString:@"(\""];
    [q appendString:[[_fields allKeys] componentsJoinedByString:@"\", \""]];
    [q appendString:@"\") VALUES("];
    int i = 0;
    for(id fieldName in _fields) {
        if(__builtin_expect(i++ > 0, 1))
            [q appendString:@", "];

        id obj = _fields[fieldName];
        [p addObject:obj ? obj : [NSNull null]];
        [q appendFormat:@"$%lu", (unsigned long)[p count]];
    }
    [q appendString:@")"];

    return [self _generateWhereString:q parameters:p];
}

- (NSArray *)executeOnConnection:(DBConnection *)connection error:(NSError *__autoreleasing *)outErr
{
    NSArray *ret = [super executeOnConnection:connection error:outErr];

    // For inserts where a model class is available, we return the inserted object
    Class modelClass;
    if(ret && (modelClass = [_table modelClass])) {
       // Model classes require there to be an auto incremented id column so we just select the last id
       return @[[[[_table select] order:DBOrderDescending by:@[@"id"]] limit:@1][0]];
    } else
        return ret;
}

@end

@implementation DBUpdateQuery

+ (NSString *)_queryType
{
    return @"UPDATE ";
}

- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    [q appendString:[[self class] _queryType]];

    [q appendString:[_table toString]];
    [q appendString:@" SET \""];
    int i = 0;
    for(id fieldName in _fields) {
        if(__builtin_expect(i++ > 0, 1))
            [q appendString:@", \""];
        [q appendString:fieldName];
        [q appendString:@"\"="];
        id obj = _fields[fieldName];
        if(!obj || [obj isEqual:[NSNull null]]) {
            [q appendString:@"NULL"];
        } else {
            [self _addParam:obj withToken:YES currentParams:p query:q];
        }
    }

    return [self _generateWhereString:q parameters:p];
}

@end
