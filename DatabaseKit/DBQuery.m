#import "DBQuery.h"
#import "DBTable.h"
#import "DBModel.h"
#import "DBModelPrivate.h"
#import "Debug.h"

NSString *const DBSelectAll = @"*";

NSString *const DBOrderDescending = @" DESC";
NSString *const DBOrderAscending  = @" ASC";

NSString *const DBInnerJoin = @" INNER ";
NSString *const DBLeftJoin  = @" LEFT ";

NSString *const DBUnion    = @" UNION ";
NSString *const DBUnionAll = @" UNION ALL ";

static NSString *const DBStringConditions = @"DBStringConditions";

@interface DBQuery () {
    @protected
    DBTable *_table;
    id _fields;
    NSDictionary *_where;

    BOOL _dirty;
    NSArray *_rows;
}
@property(readwrite, strong) DBTable *table;
@property(readwrite, strong) id fields;
@property(readwrite, strong) NSDictionary *where;

+ (NSString *)_queryType;

- (BOOL)_generateString:(NSMutableString *)query parameters:(NSMutableArray *)parameters;
- (id)_copyWithSubclass:(Class)aClass;
@end

@interface DBSelectQuery ()
@property(readwrite, strong) NSArray *orderedBy;
@property(readwrite, strong) NSArray *groupedBy;
@property(readwrite, strong) NSString *order;
@property(readwrite, strong) NSNumber *limit, *offset;
@property(readwrite, strong) id join;
@property(readwrite, strong) DBSelectQuery *unionQuery;
@property(readwrite, strong) NSString *unionType;
@end

@implementation DBQuery

+ (NSString *)_queryType
{
    [NSException raise:NSInternalInconsistencyException
                format:@"DBQuery does not implement SQL generation."];
    return nil;
}

+ (instancetype)withTable:(DBTable *)table
{
    DBQuery *ret = [self new];
    ret.table    = table;
    return ret;
}

#pragma mark - Derivatives

#define IsArr(x) ([x isKindOfClass:[NSArray class]] || ([NSPointerArray class] && [x isKindOfClass:[NSPointerArray class]]))
#define IsDic(x) ([x isKindOfClass:[NSDictionary class]] || [x isKindOfClass:[NSMapTable class]])
#define IsStr(x) ([x isKindOfClass:[NSString class]])
#define IsAS(x)  ([x isKindOfClass:[DBAs class]])

- (DBQuery *)select:(id<DBIndexedCollection>)fields
{
    NSParameterAssert(!fields || IsArr(fields));
    DBQuery *ret = [self _copyWithSubclass:[DBSelectQuery class]];
    ret.fields = !fields         ? nil
                 : IsArr(fields) ? fields
                                 : @[fields];
    return ret;
}
- (DBSelectQuery *)select
{
    return [self select:nil];
}

- (DBInsertQuery *)insert:(id<DBKeyedCollection>)fields
{
    NSParameterAssert(IsDic(fields));
    DBInsertQuery *ret = [self _copyWithSubclass:[DBInsertQuery class]];
    ret.fields = fields;
    return ret;
}
- (DBUpdateQuery *)update:(id<DBKeyedCollection>)fields
{
    NSParameterAssert(IsDic(fields));
    DBUpdateQuery *ret = [self _copyWithSubclass:[DBUpdateQuery class]];
    ret.fields = fields;
    return ret;
}
- (DBDeleteQuery *)delete
{
    DBDeleteQuery *ret = [self _copyWithSubclass:[DBDeleteQuery class]];
    ret.fields = nil;
    return ret;
}
- (instancetype)where:(id)conds
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
- (instancetype)appendWhere:(id)conds
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


#pragma mark -

- (BOOL)_addParam:(id)param
        withToken:(BOOL)addToken
    currentParams:(NSMutableArray *)params
            query:(NSMutableString *)query
{
    if([param isKindOfClass:[DBQuery class]]) {
        if(![param _generateString:query parameters:params])
            return NO;
        addToken = NO;
    } else if(!param)
        [params addObject:[NSNull null]];
    else
        [params addObject:param];
    if(addToken)
        [query appendFormat:@"$%ld", (unsigned long)[params count]];
    return YES;
}

- (BOOL)_generateWhereString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSParameterAssert(q && p);

    if([_where count] == 0)
        return YES;

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
            [q appendString:@"\""];
            [q appendString:fieldName];
            [q appendString:@"\"="];
            [self _addParam:_where[fieldName] withToken:YES currentParams:p query:q];
        }
    }
    return YES;
}

- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSParameterAssert(q && p);
    [q appendString:[[self class] _queryType]];
    return YES;
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
    NSMutableString *query = [NSMutableString new];
    NSMutableArray  *params = [NSMutableArray new];
    NSAssert([self _generateString:query parameters:params], @"Failed to generate SQL");

    NSArray *ret = [connection executeSQL:query substitutions:params error:&err];
    if(!ret) {
        if(outErr)
            *outErr = err;
        return nil;
    }
    return ret;
}

#pragma mark -

- (DBConnection *)connection
{
    return _table.database.connection;
}

- (NSString *)toString
{
    NSMutableString *ret = [NSMutableString new];
    [self _generateString:ret parameters:[NSMutableArray new]];
    return ret;
}

- (NSString *)description
{
    return [self toString];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [self _copyWithSubclass:[self class]];
}

- (id)_copyWithSubclass:(Class)aClass
{
    NSParameterAssert([aClass isSubclassOfClass:[DBQuery class]]);
    DBQuery *copy   = [aClass new];
    copy.table      = _table;
    copy.fields     = _fields;
    copy.where      = _where;
    return copy;
}
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

- (instancetype)order:(NSString *)order by:(id)fields
{
    BOOL isStr = IsStr(fields);
    NSParameterAssert(IsArr(fields) || isStr);
    DBSelectQuery *ret = [self copy];
    ret.order = order;
    ret.orderedBy = isStr ? @[fields] : fields;
    return ret;
}
- (instancetype)orderBy:(id)fields
{
    return [self order:DBOrderAscending by:fields];
}

- (instancetype)groupBy:(id)fields
{
    BOOL isStr = IsStr(fields);
    NSParameterAssert(IsArr(fields) || isStr);
    DBSelectQuery *ret = [self copy];
    ret.groupedBy = isStr ? @[fields] : fields;
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

@implementation DBInsertQuery

+ (NSString *)_queryType
{
    return @"INSERT ";
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
       return @[[[[_table select] order:DBOrderDescending by:@"id"] limit:@1][0]];
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

@implementation DBDeleteQuery

+ (NSString *)_queryType
{
    return @"DELETE ";
}

- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSParameterAssert(q && p);
    [q appendString:[[self class] _queryType]];

    [q appendString:@"FROM "];
    [q appendString:[_table toString]];

    return [self _generateWhereString:q parameters:p];
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
    NSMutableString *ret = [NSMutableString stringWithString:_field];
    [ret appendString:@" AS "];
    [ret appendString:_alias];
    return ret;
}
- (NSString *)description
{
    return [self toString];
}
@end