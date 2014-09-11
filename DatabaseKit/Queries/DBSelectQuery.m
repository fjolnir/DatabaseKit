#import "DBSelectQuery.h"
#import "DBQuery+Private.h"
#import "DBTable.h"
#import "DBModel+Private.h"

@interface DBSelectQuery ()
@property(readwrite, strong) NSArray *orderedBy;
@property(readwrite, strong) NSArray *groupedBy;
@property(readwrite, strong) NSString *order;
@property(readwrite, strong) NSNumber *limit, *offset;
@property(readwrite, strong) id join;
@property(readwrite, strong) DBSelectQuery *unionQuery;
@property(readwrite, strong) NSString *unionType;
@end

@implementation DBSelectQuery

+ (NSString *)_queryType
{
    return @"SELECT ";
}

- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSParameterAssert(q && p);
    [q appendString:[[self class] _queryType]];

    if(_fields == nil)
        [q appendString:DBSelectAll];
    else {
        int i = 0;
        for(id field in _fields) {
            if(__builtin_expect(i++ > 0, 1))
                [q appendString:@", "];
            if([field isKindOfClass:[NSString class]]) {
                [q appendString:@"\""];
                [q appendString:[field stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
                [q appendString:@"\""];
            } else
                [q appendString:[field toString]];
        }
    }
    [q appendString:@" FROM "];
    [q appendString:[_table toString]];

    if(_join) {
        if([_join isKindOfClass:[DBJoin class]]) {
            DBJoin *join = _join;
            NSString *tableName     = [_table toString];
            NSString *joinTableName = [join.table toString];
            NSDictionary *joinFields = join.fields;
            [q appendString:join.type];
            [q appendString:@" JOIN "];
            [q appendString:joinTableName];
            [q appendString:@" ON "];
            int i = 0;
            for(id key in join.fields) {
                if(i++ > 0)
                    [q appendString:@" AND "];
                [q appendString:joinTableName];
                [q appendString:@".\""];
                [q appendString:joinFields[key]];
                [q appendString:@"\"="];
                [q appendString:tableName];
                [q appendString:@".\""];
                [q appendString:key];
                [q appendString:@"\""];
            }
        } else {
            [q appendString:@" "];
            [q appendString:[_join toString]];
        }
    }

    [self _generateWhereString:q parameters:p];

    if(_groupedBy) {
        [q appendString:@" GROUP BY "];
        [q appendString:[_groupedBy componentsJoinedByString:@", "]];
    }
    if(_unionQuery) {
        [q appendString:_unionType];
        if(![self _addParam:_unionQuery withToken:NO currentParams:p query:q])
            return false;
    }
    if(_order && _orderedBy) {
        [q appendString:@" ORDER BY \""];
        [q appendString:[_orderedBy componentsJoinedByString:[NSString stringWithFormat:@"\" %@, ", _order]]];
        [q appendString:@"\""];
        [q appendString:_order];
    }

    if([_limit unsignedIntegerValue] > 0)
        [q appendFormat:@" LIMIT %ld", [_limit unsignedLongValue]];
    if([_offset unsignedIntegerValue] > 0)
        [q appendFormat:@" OFFSET %ld", [_offset unsignedLongValue]];

    return YES;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len;
{
    if(!_rows || _dirty)
        _rows = [self execute];
    return [_rows countByEnumeratingWithState:state objects:buffer count:len];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    if(!_rows || _dirty)
        _rows = [self execute];
    NSDictionary *row = _rows[idx];
    Class modelClass = [_table modelClass];
    if(modelClass && row[@"id"]) {
        DBModel *model = [[modelClass alloc] initWithTable:_table
                                                databaseId:[row[@"id"] unsignedIntegerValue]];
        if(_fields == nil && [DBModel enableCache])
            model.readCache = [row mutableCopy];
        return model;
    }
    return row;
}

- (id)first
{
    return [self count] > 0 ? self[0] : nil;
}

- (NSUInteger)count
{
    if(_rows && !_dirty)
        return [_rows count];
    else if(_groupedBy || _offset || _limit || _unionQuery) {
        return [[self execute] count];
    }
    return [[self select:@[[DBAs field:@"COUNT(*)" alias:@"count"]]][0][@"count"] unsignedIntegerValue];
}

- (instancetype)order:(NSString *)order by:(NSArray *)fields
{
    DBSelectQuery *ret = [self copy];
    ret.order = order;
    ret.orderedBy = fields;
    return ret;
}
- (instancetype)orderBy:(id)fields
{
    return [self order:DBOrderAscending by:fields];
}

- (instancetype)groupBy:(NSArray *)fields
{
    DBSelectQuery *ret = [self copy];
    ret.groupedBy = fields;
    return ret;
}

- (instancetype)limit:(NSNumber *)limit
{
    DBSelectQuery *ret = [self copy];
    ret.limit = limit;
    return ret;
}

- (instancetype)offset:(NSNumber *)offset
{
    DBSelectQuery *ret = [self copy];
    ret.offset = offset;
    return ret;
}

- (instancetype)join:(NSString *)type withTable:(id)table on:(NSDictionary *)fields
{
    DBSelectQuery *ret = [self copy];
    ret.join = [DBJoin withType:type table:table fields:fields];
    return ret;
}
- (instancetype)innerJoin:(id)table on:(NSDictionary *)fields
{
    return [self join:DBInnerJoin withTable:table on:fields];
}
- (instancetype)leftJoin:(id)table on:(NSDictionary *)fields
{
    return [self join:DBLeftJoin withTable:table on:fields];
}

- (instancetype)union:(DBSelectQuery *)otherQuery
{
    return [self union:otherQuery type:DBUnion];
}

- (instancetype)union:(DBSelectQuery *)otherQuery type:(NSString *)type
{
    DBSelectQuery *ret = [self copy];
    ret.unionQuery = otherQuery;
    ret.unionType  = type;
    return ret;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    DBSelectQuery *copy   = [super copyWithZone:zone];
    copy.orderedBy  = _orderedBy;
    copy.groupedBy  = _groupedBy;
    copy.order      = _order;
    copy.offset     = _offset;
    copy.limit      = _limit;
    copy.join       = _join;
    copy.unionQuery = _unionQuery;
    copy.unionType  = _unionType;
    return copy;
}

@end
