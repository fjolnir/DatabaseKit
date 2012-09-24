#import "ARQuery.h"
#import "ARTable.h"
#import "ARBase.h"

NSString *const AROrderDescending = @"DESC";
NSString *const AROrderAscending  = @"ASC";

NSString *const ARQueryTypeSelect = @"SELECT";
NSString *const ARQueryTypeInsert = @"INSERT";
NSString *const ARQueryTypeUpdate = @"UPDATE";
NSString *const ARQueryTypeDelete = @"DELETE";

NSString *const ARStringCondition = @"ARStringCondition";

@interface ARQuery () {
    BOOL _dirty;
    NSArray *_rows;
}
@property(readwrite, retain, nonatomic) id<ARConnection> connection;
@property(readwrite, retain) NSString *type;
@property(readwrite, retain) id table;
@property(readwrite, retain) NSDictionary *parameters;
@property(readwrite, retain) id fields;
@property(readwrite, retain) id where;
@property(readwrite, retain) NSArray *orderedBy;
@property(readwrite, retain) NSString *order;
@property(readwrite, retain) NSNumber *limit;

- (BOOL)_generateString:(NSString **)outString parameters:(NSArray **)outParameters;
@end

@implementation ARQuery

+ (ARQuery *)withTable:(id)table
{
    return [self withConnection:nil table:table];
}
+ (ARQuery *)withConnection:(id<ARConnection>)connection table:(id)table
{
    NSParameterAssert(!table || [table respondsToSelector:@selector(toString)]);
    ARQuery *ret = [self new];
    ret.connection = connection;
    ret.table      = table;
    return [ret autorelease];
}

#pragma mark - Derivatives

#define IsArr(x) ([x isKindOfClass:[NSArray class]] || [x isKindOfClass:[NSPointerArray class]])
#define IsDic(x) ([x isKindOfClass:[NSDictionary class]] || [x isKindOfClass:[NSMapTable class]])
#define IsStr(x) ([x isKindOfClass:[NSString class]])
#define IsAS(x)  ([x isKindOfClass:[ARAs class]])

- (ARQuery *)select:(id)fields
{
    NSParameterAssert(IsArr(fields) || IsStr(fields) || IsAS(fields));
    ARQuery *ret = [self copy];
    ret.type = ARQueryTypeSelect;
    ret.fields = IsArr(fields) ? fields : @[fields];
    return [ret autorelease];
}
- (ARQuery *)select
{
    return [self select:@"*"];
}

- (ARQuery *)insert:(id)fields
{
    NSParameterAssert(IsDic(fields));
    ARQuery *ret = [self copy];
    ret.type = ARQueryTypeInsert;
    ret.fields = fields;
    return [ret autorelease];
}
- (ARQuery *)update:(id)fields
{
    NSParameterAssert(IsDic(fields));
    ARQuery *ret = [self copy];
    ret.type = ARQueryTypeUpdate;
    ret.fields = fields;
    return [ret autorelease];
}
- (ARQuery *)delete
{
    ARQuery *ret = [self copy];
    ret.type = ARQueryTypeDelete;
    ret.fields = nil;
    return [ret autorelease];
}
- (ARQuery *)where:(id)conds
{
    NSParameterAssert(IsArr(conds) || IsDic(conds) || IsStr(conds));
    ARQuery *ret = [self copy];
    ret.where = conds;
    return [ret autorelease];
}
- (ARQuery *)appendWhere:(id)conds
{
    if(!_where)
        return [self where:conds];
    BOOL isStr = IsStr(conds);
    NSParameterAssert(IsArr(conds) || IsDic(conds) || isStr);
    ARQuery *ret = [self copy];

    NSMutableDictionary *derivedConds = [_where copy];
    if(isStr)
        derivedConds[ARStringCondition] = _where[ARStringCondition] ? [_where[ARStringCondition] stringByAppendingFormat:@" AND %@", conds] : conds;
    else {
        for(id key in conds) {
            derivedConds[key] = conds[key];
        }
    }
    ret.where = derivedConds;
    return [ret autorelease];
}
- (ARQuery *)order:(NSString *)order by:(id)fields
{
    NSParameterAssert(IsArr(fields) || IsStr(fields));
    ARQuery *ret = [self copy];
    ret.order = order;
    ret.orderedBy = fields;
    return [ret autorelease];
}
- (ARQuery *)orderBy:(id)fields
{
    return [self order:AROrderAscending by:fields];
}
- (ARQuery *)limit:(NSNumber *)limit
{
    ARQuery *ret = [self copy];
    ret.limit = limit;
    return [ret autorelease];
}

#pragma mark -

- (BOOL)_generateString:(NSString **)outString parameters:(NSArray **)outParameters
{
    NSMutableString *q     = [NSMutableString stringWithString:_type];
    NSMutableArray *p = [NSMutableArray array];
    
    if([_type isEqualToString:ARQueryTypeSelect]) {
        [q appendFormat:@" %@ FROM %@", [_fields componentsJoinedByString:@", "], [_table toString]];
    } else if([_type isEqualToString:ARQueryTypeInsert]) {
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
    } else if([_type isEqualToString:ARQueryTypeUpdate]) {
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
    } else if([_type isEqualToString:ARQueryTypeDelete]) {
        [q appendFormat:@" FROM %@", [_table toString]];
    } else {
        NSAssert(NO, @"Unknown query type: %@", _type);
        return NO;
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
    NSString *query;
    NSArray *params;
    [self _generateString:&query parameters:&params];
    NSError *err = nil;
    id ret = [[self connection] executeSQL:query substitutions:params error:&err];
    if(err) {
        NSLog(@"%@", err);
        return nil;
    }
    return ret;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    if(!_rows || _dirty)
        _rows = [self execute];
    return _rows[idx];
}

- (NSUInteger)count
{
    if(_rows && !_dirty)
        return [_rows count];
    return [[self select:@"COUNT(*) AS count"][0][@"count"] unsignedIntegerValue];
}
#pragma mark -

- (id<ARConnection>)connection
{
    if(_connection)
        return _connection;
    else if([_table isKindOfClass:[ARTable class]])
        return [(ARTable *)_table connection];
    return [ARBase defaultConnection];
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
    ARQuery *copy = [[self class] new];
    copy.type      = _type;
    copy.table     = _table;
    copy.fields    = _fields;
    copy.where     = _where;
    copy.orderedBy = _orderedBy;
    copy.order     = _order;
    copy.limit     = _limit;
    return copy;
}
@end

@implementation ARAs
+ (ARAs *)field:(NSString *)field alias:(NSString *)alias
{
    return [[self alloc] initWithField:field alias:alias];
}

- (id)initWithField:(NSString *)field alias:(NSString *)alias
{
    if(!(self = [super init]))
        return nil;
    _field = [field retain];
    _alias = [alias retain];
    return self;
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