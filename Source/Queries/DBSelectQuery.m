#import <objc/runtime.h>
#import "DBSelectQuery.h"
#import "DBQuery+Private.h"
#import "DBTable.h"
#import "DBModel+Private.h"
#import "DBUtilities.h"
#import "NSPredicate+DBSQLRepresentable.h"
#import "NSCollections+DBAdditions.h"

NSString *const DBInnerJoin = @" INNER ";
NSString *const DBLeftJoin  = @" LEFT ";

NSString *const DBUnion    = @" UNION ";
NSString *const DBUnionAll = @" UNION ALL ";

@interface DBJoin ()
@property(readwrite, strong) NSString *type;
@property(readwrite, strong) DBTable *table;
@property(readwrite, strong) NSPredicate *predicate;

- (BOOL)_generateString:(NSMutableString *)q query:(DBSelectQuery *)query parameters:(NSMutableArray *)p;
@end

@interface DBSelectQuery ()
@property(readwrite, strong) DBSelectQuery *subQuery;
@property(readwrite, strong) NSArray *orderedBy;
@property(readwrite, strong) NSArray *groupedBy;
@property(readwrite)         DBOrder order;
@property(readwrite)         NSUInteger limit, offset;
@property(readwrite, strong) DBJoin *join;
@property(readwrite, strong) DBSelectQuery *unionQuery;
@property(readwrite, strong) NSString *unionType;
@property(readwrite)         BOOL distinct;
@end

@implementation DBSelectQuery

+ (instancetype)fromSubquery:(DBSelectQuery *)aSubQuery
{
    DBSelectQuery * const query = [self new];
    query->_table = aSubQuery.table;
    query->_subQuery = aSubQuery;
    return query;
}

- (BOOL)canCombineWithQuery:(DBSelectQuery * const)aQuery
{
    return aQuery.class == self.class
        && DBEqual(_where, aQuery.where)
        && DBEqual(_table,aQuery.table)
        && DBEqual(_orderedBy, aQuery.orderedBy)
        && DBEqual(_groupedBy, aQuery.groupedBy)
        && _order == aQuery.order
        && _limit == aQuery.limit
        && _offset == aQuery.offset
        && !_unionQuery && !aQuery.unionType;
}

- (instancetype)combineWith:(DBQuery * const)aQuery
{
    NSParameterAssert([self canCombineWithQuery:aQuery]);

    if([aQuery isEqual:self])
        return self;

    DBSelectQuery * const combined = [self copy];
    combined.columns = [_columns arrayByAddingObjectsFromArray:aQuery.columns];
    return combined;
}


- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSParameterAssert(q && p);
    [q appendString:@"SELECT "];

    if(_distinct)
        [q appendString:@"DISTINCT "];

    if(_columns == nil)
        [q appendString:@"*"];
    else
        [q appendString:[[_columns db_map:^(id<DBSQLRepresentable> obj) {
            return [obj sqlRepresentationForQuery:self withParameters:p];
        }] componentsJoinedByString:@", "]];

    [q appendString:@" FROM "];
    if(_subQuery) {
        [q appendString:@"("];
        [_subQuery _generateString:q parameters:p];
        [q appendString:@")"];
    } else {
        [q appendString:@"`"];
        [q appendString:_table.name];
        [q appendString:@"`"];
    }

    [_join _generateString:q query:self parameters:p];

    if(_where) {
        [q appendString:@" WHERE "];
        [q appendString:[_where sqlRepresentationForQuery:self withParameters:p]];
    }
    if(_groupedBy) {
        [q appendString:@" GROUP BY `"];
        [q appendString:[_groupedBy componentsJoinedByString:@"`, "]];
        [q appendString:@"`"];
    }
    if(_unionQuery) {
        [q appendString:_unionType];
        if(![self _addParam:_unionQuery withToken:NO currentParams:p query:q])
            return false;
    }
    if(_orderedBy) {
        [q appendString:@" ORDER BY `"];
        switch (_order) {
            case DBOrderAscending:
                [q appendString:[_orderedBy componentsJoinedByString:@"` ASC, "]];
                [q appendString:@"` ASC"];
                break;
            case DBOrderDescending:
                [q appendString:[_orderedBy componentsJoinedByString:@"` DESC, "]];
                [q appendString:@"` DESC"];
                break;
            default:
                [NSException raise:NSInternalInconsistencyException
                            format:@"Invalid order"];
        }
    }

    if(_limit > 0)
        [q appendFormat:@" LIMIT %lu", (unsigned long)_limit];
    if(_offset > 0)
        [q appendFormat:@" OFFSET %lu", (unsigned long)_offset];

    return YES;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    return [[[[self offset:idx] limit:1] execute:NULL] firstObject];
}

- (id)firstObject
{
    return self[0];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)bufLen;

{
    NSArray *results;
    if(state->state == 0) {
        state->state = 1;

        results = [self execute:NULL];
        state->mutationsPtr = (__bridge void *)results;
    } else
        results = (__bridge_transfer id)(void *)state->extra[0];

    state->itemsPtr = buffer;

    NSUInteger *ofs = &state->extra[1];
    NSUInteger len  = MIN(bufLen, results.count - *ofs);
    if(len > 0) {
        [results getObjects:buffer range:(NSRange) { *ofs, len }];
        state->extra[0] = (__bridge_retained void *)results;
        *ofs += len;
    }
    return len;
}


- (NSUInteger)count
{
    if(_groupedBy || _offset || _limit || _unionQuery)
        return [[self execute:NULL] count];
    else
        return [[self select:@[[DBAs field:@"COUNT(*)" alias:@"count"]]][0][@"count"] unsignedIntegerValue];
}

- (instancetype)order:(DBOrder)order by:(NSArray *)columns
{
    DBSelectQuery *ret = [self copy];
    ret.order = order;
    ret.orderedBy = columns;
    return ret;
}
- (instancetype)orderBy:(id)columns
{
    return [self order:DBOrderAscending by:columns];
}

- (instancetype)groupBy:(NSArray *)columns
{
    DBSelectQuery *ret = [self copy];
    ret.groupedBy = columns;
    return ret;
}

- (instancetype)limit:(NSUInteger)limit
{
    DBSelectQuery *ret = [self copy];
    ret.limit = limit;
    return ret;
}

- (instancetype)offset:(NSUInteger)offset
{
    DBSelectQuery *ret = [self copy];
    ret.offset = offset;
    return ret;
}

- (instancetype)distinct:(BOOL)distinct
{
    DBSelectQuery *ret = [self copy];
    ret.distinct = distinct;
    return ret;
}

- (instancetype)join:(DBJoin * const)join
{
    DBSelectQuery *ret = [self copy];
    ret.join = join;
    return ret;
}
- (instancetype)innerJoin:(id)table on:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSPredicate * const predicate = [NSPredicate predicateWithFormat:format arguments:args];
    va_end(args);
    return [self join:[DBJoin withType:DBInnerJoin table:table predicate:predicate]];
}
- (instancetype)leftJoin:(id)table on:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSPredicate * const predicate = [NSPredicate predicateWithFormat:format arguments:args];
    va_end(args);
    return [self join:[DBJoin withType:DBLeftJoin table:table predicate:predicate]];
}

- (instancetype)union:(DBSelectQuery *)otherQuery
{
    return [self union:otherQuery type:DBUnion];
}

- (instancetype)union:(DBSelectQuery *)otherQuery type:(NSString *)type
{
    DBSelectQuery *ret = [self copy];
    if(otherQuery.orderedBy) {
        if(!ret.orderedBy)
            ret.order = otherQuery.order;

        NSMutableArray * const orderedBy = [ret.orderedBy mutableCopy] ?: [NSMutableArray new];
        for(NSString *column in otherQuery.orderedBy) {
            if(![orderedBy containsObject:column])
                [orderedBy addObject:column];
        }
        ret.orderedBy = orderedBy;
    }
    ret.unionQuery = [otherQuery orderBy:nil];
    ret.unionType  = type;
    return ret;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    DBSelectQuery *copy   = [super copyWithZone:zone];
    copy->_orderedBy  = _orderedBy;
    copy->_groupedBy  = _groupedBy;
    copy->_order      = _order;
    copy->_offset     = _offset;
    copy->_limit      = _limit;
    copy->_join       = _join;
    copy->_unionQuery = _unionQuery;
    copy->_unionType  = _unionType;
    copy->_subQuery   = _subQuery;
    copy->_distinct   = _distinct;
    return copy;
}

- (NSArray *)executeOnConnection:(DBConnection *)connection error:(NSError *__autoreleasing *)outErr
{
    NSArray *results = [super executeOnConnection:connection error:outErr];

    NSMutableString *query  = [NSMutableString new];
    NSMutableArray  *params = [NSMutableArray new];
    NSAssert([self _generateString:query parameters:params], @"Failed to generate SQL");
    DBResult *result = [connection execute:query substitutions:params error:outErr];

    BOOL const selectingEntireTable = self.columns == nil
                                   || [self.columns isEqual:@[[self.table.name stringByAppendingString:@".*"]]];
    Class modelClass = self.table.modelClass;
    if(selectingEntireTable && [results count] > 0 && modelClass) {
        NSMutableArray *modelObjects = [NSMutableArray arrayWithCapacity:[results count]];
        NSSet *fieldNames = [NSSet setWithArray:[[results firstObject] allKeys]];
        if([fieldNames isSubsetOfSet:self.table.columns]) {
            while([result step:outErr] == DBResultStateNotAtEnd) {
                [modelObjects addObject:[[modelClass alloc]
                                         initWithDatabase:self.table.database
                                         result:result]];
            }
            return result.state == DBResultStateAtEnd
                 ? modelObjects
                 : nil;
        }
    }
    return [result toArray:outErr];
}
@end


@implementation DBJoin
+ (DBJoin *)withType:(NSString *)type table:(DBTable *)table predicate:(NSPredicate *)predicate
{
    DBJoin *ret = [self new];
    ret.type   = type;
    ret.table  = table;
    ret.predicate = predicate;
    return ret;
}
- (BOOL)_generateString:(NSMutableString *)q query:(DBSelectQuery *)query parameters:(NSMutableArray *)p
{
    [q appendString:_type];
    [q appendString:@" JOIN `"];
    [q appendString:_table.name];
    [q appendString:@"` ON "];
    [q appendString:[_predicate sqlRepresentationForQuery:query withParameters:p]];
    return YES;
}
- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ JOIN %@ ON %@", _type, _table, _predicate];
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

- (NSString *)sqlRepresentationForQuery:(DBQuery *)query
                         withParameters:(NSMutableArray *)parameters
{
    NSMutableString *ret = [NSMutableString stringWithString:_field];
    [ret appendString:@" AS "];
    [ret appendString:_alias];
    return ret;
}

- (NSString *)description
{
    return [self sqlRepresentationForQuery:nil withParameters:nil];
}
@end

@implementation DBQuery (DBSelectQuery)
- (DBQuery *)select:(NSArray *)columns
{
    DBQuery *ret = [self isKindOfClass:[DBSelectQuery class]]
                 ? [self copy]
                 : [self _copyWithSubclass:[DBSelectQuery class]];
    ret.columns = columns;
    return ret;
}
- (DBSelectQuery *)select
{
    return [self select:nil];
}
@end
