#import "DBQuery.h"
#import "DBTable.h"
#import "DBModel.h"
#import "DBModelPrivate.h"
#import "Debug.h"

NSString *const DBSelectAll = @"*";

NSString *const DBOrderDescending = @" DESC";
NSString *const DBOrderAscending  = @" ASC";

NSString *const DBQueryTypeSelect = @"SELECT ";
NSString *const DBQueryTypeInsert = @"INSERT ";
NSString *const DBQueryTypeUpdate = @"UPDATE ";
NSString *const DBQueryTypeDelete = @"DELETE ";

NSString *const DBInnerJoin = @" INNER ";
NSString *const DBLeftJoin  = @" LEFT ";

NSString *const DBUnion    = @" UNION ";
NSString *const DBUnionAll = @" UNION ALL ";

static NSString *const DBStringConditions = @"DBStringConditions";

@interface DBQuery () {
    BOOL _dirty;
    NSArray *_rows;
}
@property(readwrite, strong) NSString *type;
@property(readwrite, strong) DBTable *table;
@property(readwrite, strong) id fields;
@property(readwrite, strong) NSDictionary *where;
@property(readwrite, strong) NSArray *orderedBy;
@property(readwrite, strong) NSArray *groupedBy;
@property(readwrite, strong) NSString *order;
@property(readwrite, strong) NSNumber *limit, *offset;
@property(readwrite, strong) id join;
@property(readwrite, strong) DBQuery *unionQuery;
@property(readwrite, strong) NSString *unionType;

- (BOOL)_generateString:(NSString **)outString parameters:(NSMutableArray **)outParameters;
@end

@implementation DBQuery

+ (DBQuery *)withTable:(DBTable *)table
{
    DBQuery *ret = [self new];
    ret.table    = table;
    ret.type     = DBQueryTypeSelect;
    ret.fields   = @[@"*"];
    return ret;
}

#pragma mark - Derivatives

#define IsArr(x) ([x isKindOfClass:[NSArray class]] || ([NSPointerArray class] && [x isKindOfClass:[NSPointerArray class]]))
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

    if(IsStr(conds))
        ret.where = @{ DBStringConditions: [@[@[conds]] mutableCopy] };
    else if(IsArr(conds))
        ret.where = @{ DBStringConditions: [@[conds] mutableCopy] };
    else
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

    NSMutableDictionary *derivedConds = [_where mutableCopy];
    derivedConds[DBStringConditions] = [_where[DBStringConditions] mutableCopy];
    if(isStr) {
        if(!derivedConds[DBStringConditions])
            derivedConds[DBStringConditions] = [NSMutableArray new];
        [derivedConds[DBStringConditions] addObject:@[conds]];
    } else {
        for(id key in conds) {
            derivedConds[key] = conds[key];
        }
    }
    ret.where = derivedConds;
    return ret;
}

- (DBQuery *)order:(NSString *)order by:(id)fields
{
    BOOL isStr = IsStr(fields);
    NSParameterAssert(IsArr(fields) || isStr);
    DBQuery *ret = [self copy];
    ret.order = order;
    ret.orderedBy = isStr ? @[fields] : fields;
    return ret;
}
- (DBQuery *)orderBy:(id)fields
{
    return [self order:DBOrderAscending by:fields];
}

- (DBQuery *)groupBy:(id)fields
{
    BOOL isStr = IsStr(fields);
    NSParameterAssert(IsArr(fields) || isStr);
    DBQuery *ret = [self copy];
    ret.groupedBy = isStr ? @[fields] : fields;
    return ret;
}

- (DBQuery *)limit:(NSNumber *)limit
{
    DBQuery *ret = [self copy];
    ret.limit = limit;
    return ret;
}

- (DBQuery *)offset:(NSNumber *)offset
{
    DBQuery *ret = [self copy];
    ret.offset = offset;
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

- (DBQuery *)union:(DBQuery *)otherQuery
{
    return [self union:otherQuery type:DBUnion];
}

- (DBQuery *)union:(DBQuery *)otherQuery type:(NSString *)type
{
    DBQuery *ret = [self copy];
    ret.unionQuery = otherQuery;
    ret.unionType  = type;
    return ret;
}

#pragma mark -

- (BOOL)_addParam:(id)param
        withToken:(BOOL)addToken
    currentParams:(NSMutableArray *)params
            query:(NSMutableString *)query
{
    if([param isKindOfClass:[DBQuery class]]) {
        NSString *subQuery;
        if(![param _generateString:&subQuery parameters:&params])
            return NO;
        [query appendString:subQuery];
        addToken = NO;
    } else if(!param)
        [params addObject:[NSNull null]];
    else
        [params addObject:param];
    if(addToken)
        [query appendFormat:@"$%ld", (unsigned long)[params count]];
    return YES;
}

- (BOOL)_generateString:(NSString **)outString parameters:(NSMutableArray **)outParameters
{
    NSMutableString *q = [NSMutableString stringWithString:_type];
    NSMutableArray *p = outParameters && *outParameters
                        ? *outParameters
                        : [NSMutableArray array];
    
    if(__builtin_expect([_type isEqualToString:DBQueryTypeSelect], YES)) {
        [q appendString:[_fields componentsJoinedByString:@", "]];
        [q appendString:@" FROM "];
        [q appendString:[_table toString]];
    } else if([_type isEqualToString:DBQueryTypeInsert]) {
        [q appendString:@" INTO "];
        [q appendString:[_table toString]];
        [q appendString:@"("];
        [q appendString:[[_fields allKeys] componentsJoinedByString:@", "]];
        [q appendString:@") VALUES("];
        int i = 0;
        for(id fieldName in _fields) {
            if(__builtin_expect(i++ > 0, 1))
                [q appendString:@", "];

            id obj = _fields[fieldName];
            [p addObject:obj ? obj : [NSNull null]];
            [q appendFormat:@"$%lu", (unsigned long)[p count]];
        }
        [q appendString:@")"];
    } else if([_type isEqualToString:DBQueryTypeUpdate]) {
        [q appendString:[_table toString]];
        [q appendString:@" SET "];
        int i = 0;
        for(id fieldName in _fields) {
            if(__builtin_expect(i++ > 0, 1))
                [q appendString:@", "];
            [q appendString:fieldName];
            [q appendString:@"="];
            id obj = _fields[fieldName];
            if(!obj || [obj isEqual:[NSNull null]]) {
                [q appendString:@"NULL"];
            } else {
                [self _addParam:obj withToken:YES currentParams:p query:q];
            }
        }
    } else if([_type isEqualToString:DBQueryTypeDelete]) {
        [q appendString:@"FROM "];
        [q appendString:[_table toString]];
    } else {
        NSAssert1(NO, @"Unknown query type: %@", _type);
        return NO;
    }

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
                [q appendString:@"."];
                [q appendString:joinFields[key]];
                [q appendString:@"="];
                [q appendString:tableName];
                [q appendString:@"."];
                [q appendString:key];
            }
        } else {
            [q appendString:@" "];
            [q appendString:[_join toString]];
        }
    }

    if(_where && [_where count] > 0) {
        [q appendString:@" WHERE "];
        int i = 0;
        for(NSString *fieldName in _where) {
            
            if([fieldName isEqualToString:DBStringConditions]) {
                for(NSArray *cond in _where[fieldName]) {
                    if(i++ > 0)
                        [q appendString:@" AND "];

                    NSMutableString *condStr = [cond[0] mutableCopy];
                    for(int j = 1; j < [cond count]; ++j) {
                        [self _addParam:cond[j] withToken:NO currentParams:p query:q];
                        [condStr replaceOccurrencesOfString:[NSString stringWithFormat:@"$%d", j]
                                                 withString:[NSString stringWithFormat:@"$%lu", (unsigned long)[p count]]
                                                    options:0
                                                      range:(NSRange){ 0, [condStr length] }];
                    }
                    [q appendString:@"("];
                    [q appendString:condStr];
                    [q appendString:@") "];

                }
            } else {
                if(i++ > 0)
                    [q appendString:@" AND "];
                [q appendString:fieldName];
                [q appendString:@" IS "];
                [self _addParam:_where[fieldName] withToken:YES currentParams:p query:q];
            }
        }
    }
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
        [q appendString:@" ORDER BY "];
        [q appendString:[_orderedBy componentsJoinedByString:[NSString stringWithFormat:@"%@, ", _order]]];
        [q appendString:_order];
    }

    if([_limit unsignedIntegerValue] > 0)
        [q appendFormat:@" LIMIT %ld", [_limit unsignedLongValue]];
    if([_offset unsignedIntegerValue] > 0)
        [q appendFormat:@" OFFSET %ld", [_offset unsignedLongValue]];

    if(outString)
        *outString = q;
    if(outParameters)
        *outParameters = p;
    return true;
}

#pragma mark - Execution

- (NSArray *)execute
{
    NSError *err = nil;
    NSArray *result = [self executeOnConnection:[self connection] error:&err];
    if(err) {
        DBLog(@"%@", err);
        return nil;
    }
    return result;
}

- (NSArray *)execute:(NSError **)err
{
    return [self executeOnConnection:[self connection] error:err];
}

- (NSArray *)executeOnConnection:(DBConnection *)connection error:(NSError **)outErr
{
    NSError *err = nil;
    NSString *query;
    NSArray  *params;
    [self _generateString:&query parameters:&params];
    NSArray *ret = [connection executeSQL:query substitutions:params error:&err];
    if(!ret) {
        if(outErr)
            *outErr = err;
        return nil;
    }

    // For inserts where a model class is available, we return the inserted object
    Class modelClass;
    if([_type isEqualToString:DBQueryTypeInsert] && (modelClass = [_table modelClass])) {
        // Model classes require there to be an auto incremented id column so we just select the last id
        return @[[[[_table select] order:DBOrderDescending by:@"id"] limit:@1][0]];
    }
    return ret;
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
        if([_fields isEqual:@"*"] && [DBModel enableCache])
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
    return [[self select:@"COUNT(*) AS count"][0][@"count"] unsignedIntegerValue];
}
#pragma mark -

- (DBConnection *)connection
{
    return _table.database.connection;
}

- (NSString *)toString
{
    NSString *ret = nil;
    [self _generateString:&ret parameters:NULL];
    return ret;
}

- (NSString *)description
{
    return [self toString];
}

- (id)copyWithZone:(NSZone *)zone
{
    DBQuery *copy   = [[self class] new];
    copy.type       = _type;
    copy.table      = _table;
    copy.fields     = _fields;
    copy.where      = _where;
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
    NSMutableString *ret = [NSMutableString stringWithString:_type];
    [ret appendString:@" JOIN "];
    [ret appendString:[_table toString]];
    [ret appendString:@" ON "];
    return ret;
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
    NSMutableString *ret = [NSMutableString stringWithString:@"("];
    [ret appendString:_field];
    [ret appendString:@" AS "];
    [ret appendString:_alias];
    [ret appendString:@")"];
    return ret;
}
- (NSString *)description
{
    return [self toString];
}
@end