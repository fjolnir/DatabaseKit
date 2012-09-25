#import "DBQuery.h"
#import "DBTable.h"
#import "DBModel.h"

NSString *const DBOrderDescending = @"DESC";
NSString *const DBOrderAscending  = @"ASC";

NSString *const DBQueryTypeSelect = @"SELECT";
NSString *const DBQueryTypeInsert = @"INSERT";
NSString *const DBQueryTypeUpdate = @"UPDATE";
NSString *const DBQueryTypeDelete = @"DELETE";

NSString *const DBStringCondition = @"DBStringCondition";

NSString *const DBInnerJoin = @"INNER";
NSString *const DBLeftJoin  = @"LEFT";

@interface DBQuery () {
    BOOL _dirty;
    NSArray *_rows;
}
@property(readwrite, strong, nonatomic) DBConnection * connection;
@property(readwrite, strong) NSString *type;
@property(readwrite, strong) id table;
@property(readwrite, strong) NSDictionary *parameters;
@property(readwrite, strong) id fields;
@property(readwrite, strong) id where;
@property(readwrite, strong) NSArray *orderedBy;
@property(readwrite, strong) NSString *order;
@property(readwrite, strong) NSNumber *limit;
@property(readwrite, strong) id join;

- (BOOL)_generateString:(NSString **)outString parameters:(NSArray **)outParameters;
@end

@implementation DBQuery

+ (DBQuery *)withTable:(id)table
{
    return [self withConnection:nil table:table];
}
+ (DBQuery *)withConnection:(DBConnection *)connection table:(id)table
{
    NSParameterAssert(!table || [table respondsToSelector:@selector(toString)]);
    DBQuery *ret = [self new];
    ret.connection = connection;
    ret.table      = table;
    return ret;
}

#pragma mark - Derivatives

#define IsArr(x) ([x isKindOfClass:[NSArray class]] || [x isKindOfClass:[NSPointerArray class]])
#define IsDic(x) ([x isKindOfClass:[NSDictionary class]] || [x isKindOfClass:[NSMapTable class]])
#define IsStr(x) ([x isKindOfClass:[NSString class]])
#define IsAS(x)  ([x isKindOfClass:[DBAs class]])

- (DBQuery *)select:(id)fields
{
    NSParameterAssert(IsArr(fields) || IsStr(fields) || IsAS(fields));
    DBQuery *ret = [self copy];
    ret.type = DBQueryTypeSelect;
    ret.fields = IsArr(fields) ? fields : @[fields];
    return ret;
}
- (DBQuery *)select
{
    return [self select:@"*"];
}

- (DBQuery *)insert:(id)fields
{
    NSParameterAssert(IsDic(fields));
    DBQuery *ret = [self copy];
    ret.type = DBQueryTypeInsert;
    ret.fields = fields;
    return ret;
}
- (DBQuery *)update:(id)fields
{
    NSParameterAssert(IsDic(fields));
    DBQuery *ret = [self copy];
    ret.type = DBQueryTypeUpdate;
    ret.fields = fields;
    return ret;
}
- (DBQuery *)delete
{
    DBQuery *ret = [self copy];
    ret.type = DBQueryTypeDelete;
    ret.fields = nil;
    return ret;
}
- (DBQuery *)where:(id)conds
{
    NSParameterAssert(IsArr(conds) || IsDic(conds) || IsStr(conds));
    DBQuery *ret = [self copy];
    ret.where = conds;
    return ret;
}
- (DBQuery *)appendWhere:(id)conds
{
    if(!_where)
        return [self where:conds];
    BOOL isStr = IsStr(conds);
    NSParameterAssert(IsArr(conds) || IsDic(conds) || isStr);
    DBQuery *ret = [self copy];

    NSMutableDictionary *derivedConds = [_where copy];
    if(isStr)
        derivedConds[DBStringCondition] = _where[DBStringCondition] ? [_where[DBStringCondition] stringByAppendingFormat:@" AND %@", conds] : conds;
    else {
        for(id key in conds) {
            derivedConds[key] = conds[key];
        }
    }
    ret.where = derivedConds;
    return ret;
}

- (DBQuery *)order:(NSString *)order by:(id)fields
{
    NSParameterAssert(IsArr(fields) || IsStr(fields));
    DBQuery *ret = [self copy];
    ret.order = order;
    ret.orderedBy = fields;
    return ret;
}
- (DBQuery *)orderBy:(id)fields
{
    return [self order:DBOrderAscending by:fields];
}

- (DBQuery *)limit:(NSNumber *)limit
{
    DBQuery *ret = [self copy];
    ret.limit = limit;
    return ret;
}

- (DBQuery *)join:(NSString *)type withTable:(id)table on:(NSDictionary *)fields
{
    DBQuery *ret = [self copy];
    ret.join = [DBJoin withType:type table:table fields:fields];
    return ret;
}
- (DBQuery *)innerJoin:(id)table on:(NSDictionary *)fields
{
    return [self join:DBInnerJoin withTable:table on:fields];
}
- (DBQuery *)leftJoin:(id)table on:(NSDictionary *)fields
{
        return [self join:DBLeftJoin withTable:table on:fields];
}

#pragma mark -

- (BOOL)_generateString:(NSString **)outString parameters:(NSArray **)outParameters
{
    NSMutableString *q     = [NSMutableString stringWithString:_type];
    NSMutableArray *p = [NSMutableArray array];
    
    if([_type isEqualToString:DBQueryTypeSelect]) {
        [q appendFormat:@" %@ FROM %@", [_fields componentsJoinedByString:@", "], [_table toString]];
    } else if([_type isEqualToString:DBQueryTypeInsert]) {
        [q appendFormat:@" INTO %@(%@) VALUES(", [_table toString], [[_fields allKeys] componentsJoinedByString:@", "]];
        int i = 0;
        for(id fieldName in _fields) {
            if(i++ > 0)
                [q appendString:@", "];

            id obj = _fields[fieldName];
            if(!obj || [obj isEqual:[NSNull null]]) {
                [q appendString:@"NULL"];
            } else {
                [p addObject:obj];
                [q appendString:@"?"];
            }
        }
        [q appendString:@")"];
    } else if([_type isEqualToString:DBQueryTypeUpdate]) {
        [q appendFormat:@" %@ SET ", [_table toString]];
        int i = 0;
        for(id fieldName in _fields) {
            if(i++ > 0)
                [q appendString:@", "];
            [q appendFormat:@"%@=", fieldName];
            id obj = _fields[fieldName];
            if(!obj || [obj isEqual:[NSNull null]]) {
                [q appendString:@"NULL"];
            } else {
                [p addObject:obj];
                [q appendString:@"?"];
            }
        }
    } else if([_type isEqualToString:DBQueryTypeDelete]) {
        [q appendFormat:@" FROM %@", [_table toString]];
    } else {
        NSAssert(NO, @"Unknown query type: %@", _type);
        return NO;
    }

    if(_join) {
        if([_join isKindOfClass:[DBJoin class]]) {
            DBJoin *join = _join;
            [q appendFormat:@" %@ JOIN %@ ON ", join.type, [join.table toString]];
            int i = 0;
            for(id key in join.fields) {
                if(i++ > 0)
                    [q appendString:@" AND "];
                [q appendFormat:@"%@.%@=%@.%@", [join.table toString], join.fields[key], [_table toString], key];
            }
        } else
            [q appendFormat:@" %@", [_join toString]];
    }

    if(_where && [_where count] > 0) {
        [q appendString:@" WHERE "];
        // In case of an array, we simply have a SQL string followed by parameters
        if([_where isKindOfClass:[NSArray class]] || [_where isKindOfClass:[NSPointerArray class]]) {
            [q appendString:_where[0]];
            // TODO : Handle params
        }
        // In case of a dict, it's a key value set of equivalency tests
        else if([_where isKindOfClass:[NSDictionary class]] || [_where isKindOfClass:[NSMapTable class]]) {
            int i = 0;
            for(id fieldName in _where) {
                if(i++ > 0)
                    [q appendString:@", "];
                [q appendFormat:@"%@=", fieldName];
                id obj = _where[fieldName];
                if(!obj || [obj isEqual:[NSNull null]]) {
                    [q appendString:@"NULL"];
                } else {
                    [p addObject:obj];
                    [q appendString:@"?"];
                }
            }
        } else
            NSAssert(NO, @"query.where must be either an array or a dictionary");
    }
    if(_order && _orderedBy) {
        [q appendFormat:@" ORDER BY %@ %@", [_orderedBy componentsJoinedByString:@", "], _order];
    }

    if([_limit unsignedIntegerValue] > 0)
        [q appendFormat:@" LIMIT %ld", [_limit unsignedIntegerValue]];
    if(outString)
        *outString = q;
    if(outParameters)
        *outParameters = p;
    return true;
}

#pragma mark - Execution

- (NSArray *)execute
{
    return [self executeOnConnection:[self connection]];
}
- (NSArray *)executeOnConnection:(DBConnection *)connection
{
    NSString *query;
    NSArray *params;
    [self _generateString:&query parameters:&params];
    NSError *err = nil;
    DBLog(@"Executing query: %@ with params: %@", query, params);
    NSArray *ret = [connection executeSQL:query substitutions:params error:&err];
    if(err) {
        DBDebugLog(@"%@", err);
        return nil;
    }
    if([_type isEqualToString:DBQueryTypeInsert]) {
        NSUInteger rowId = [connection lastInsertId];
        Class modelClass;
        if(rowId > 0 && (modelClass = [_table modelClass]))
            return @[ [[modelClass alloc] initWithConnection:[self connection] id:rowId] ];
    }
    return ret;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    if(!_rows || _dirty)
        _rows = [self execute];
    NSDictionary *row = _rows[idx];
    Class modelClass = [_table modelClass];
    if(modelClass && row[@"id"])
        return [[modelClass alloc] initWithConnection:[self connection] id:[row[@"id"] unsignedIntegerValue]];
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
    return [[self select:@"COUNT(*) AS count"][0][@"count"] unsignedIntegerValue];
}
#pragma mark -

- (DBConnection *)connection
{
    if(_connection)
        return _connection;
    else if([_table isKindOfClass:[DBTable class]] && [(DBTable *)_table connection])
        return [(DBTable *)_table connection];
    return [DBModel defaultConnection];
}
- (NSString *)toString
{
    NSString *ret = nil;
    [self _generateString:&ret parameters:nil];
    return ret;
}

- (NSString *)description
{
    return [self toString];
}

- (id)copyWithZone:(NSZone *)zone
{
    DBQuery *copy  = [[self class] new];
    copy.type      = _type;
    copy.table     = _table;
    copy.fields    = _fields;
    copy.where     = _where;
    copy.orderedBy = _orderedBy;
    copy.order     = _order;
    copy.limit     = _limit;
    copy.join      = _join;
    return copy;
}
@end

@interface DBJoin ()
@property(readwrite, strong) NSString *type;
@property(readwrite, strong) id table;
@property(readwrite, strong) NSDictionary *fields;
@end
@implementation DBJoin
+ (DBJoin *)withType:(NSString *)type table:(id)table fields:(NSDictionary *)fields
{
    NSParameterAssert([table respondsToSelector:@selector(toString)]);
    DBJoin *ret = [self new];
    ret.type   = type;
    ret.table  = table;
    ret.fields = fields;
    return ret;
}
- (NSString *)toString
{
    return [NSString stringWithFormat:@"%@ JOIN %@ ON ", _type, [_table toString]];
}
- (NSString *)description
{
    return [self toString];
}
@end

@interface DBAs ()
@property(readwrite, strong) NSString *field, *alias;
@end
@implementation DBAs
+ (DBAs *)field:(NSString *)field alias:(NSString *)alias
{
    DBAs *ret = [self new];
    ret.field = field;
    ret.alias = alias;
    return ret;
}

- (NSString *)toString
{
    return [NSString stringWithFormat:@"(%@ AS %@)", _field, _alias];
}
- (NSString *)description
{
    return [self toString];
}
@end