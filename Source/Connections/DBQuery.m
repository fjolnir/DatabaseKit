#import "DBQuery.h"
#import "DBTable.h"
#import "DBModel.h"
#import "DBModelPrivate.h"

NSString *const DBSelectAll = @"*";

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
@property(readwrite, strong) NSString *type;
@property(readwrite, strong) DBTable *table;
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

+ (DBQuery *)withTable:(DBTable *)table
{
    DBQuery *ret = [self new];
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
    NSParameterAssert(IsDic(fields) || IsArr(fields));
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

- (DBQuery *)whereForPredicate:(NSPredicate *)predicate;
{
    NSParameterAssert([predicate isKindOfClass:[NSPredicate class]]);

    return [self where:[self _fetchWhereClauseForComparisonPredicate:predicate negate:NO parameterOffset:1]];
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

- (DBQuery *)appendWhereForPredicate:(NSPredicate *)predicate
{
    NSParameterAssert([predicate isKindOfClass:[NSPredicate class]]);

    return [self appendWhere:[self _fetchWhereClauseForComparisonPredicate:predicate negate:NO parameterOffset:1]];
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
        NSArray *fieldsArray = nil;
        if ([_fields isKindOfClass:[NSDictionary class]]) {
            fieldsArray = @[_fields];
        }
        else {
            fieldsArray = _fields;
        }
        [q appendFormat:@" INTO %@(%@) VALUES", [_table toString], [[fieldsArray[0] allKeys] componentsJoinedByString:@", "]];
        int offset = 0;
        for (NSDictionary *currentFields in fieldsArray) {
            if(offset > 0)
                [q appendString:@","];
                [q appendString:@"("];
            int i = 0;
            for(id fieldName in fieldsArray[0]) {
                if(i++ > 0)
                    [q appendString:@", "];

                id obj = currentFields[fieldName];
                [p addObject:obj ? obj : [NSNull null]];
                [q appendFormat:@"$%d", i + offset];
            }
            offset += i;
            [q appendString:@")"];
        }
    } else if([_type isEqualToString:DBQueryTypeUpdate]) {
        [q appendFormat:@" %@ SET ", [_table toString]];
        int i = 1;
        BOOL firstClause = YES;
        for(id fieldName in _fields) {
            if(!firstClause) {
                [q appendString:@", "];
            }
            firstClause = NO;
            [q appendFormat:@"%@=", fieldName];
            id obj = _fields[fieldName];
            if(!obj || [obj isEqual:[NSNull null]]) {
                [q appendString:@"NULL"];
            } else {
                [p addObject:obj ? obj : [NSNull null]];
                [q appendFormat:@"$%d", i];
                i++;
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
            for(int i = 1; i < [_where count]; ++i) {
                [p addObject:_where[i]];
            }
        }
        // In case of a dict, it's a key value set of equivalency tests
        else if([_where isKindOfClass:[NSDictionary class]] || [_where isKindOfClass:[NSMapTable class]]) {
            int i = 0;
            int offset = p.count;
            for(id fieldName in _where) {
                if(i++ > 0)
                    [q appendString:@", "];
                [q appendFormat:@"%@=", fieldName];
                id obj = _where[fieldName];
                [p addObject:obj ? obj : [NSNull null]];
                [q appendFormat:@"$%d", i + offset];
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

- (NSPredicateOperatorType)_negateOperator:(NSPredicateOperatorType)aOperator;
{
    NSPredicateOperatorType returnedOperator;
    
    switch (aOperator) {
        case NSLessThanPredicateOperatorType:
            returnedOperator = NSGreaterThanOrEqualToPredicateOperatorType;
            break;
        case NSLessThanOrEqualToPredicateOperatorType:
            returnedOperator = NSGreaterThanPredicateOperatorType;
            break;
        case NSGreaterThanPredicateOperatorType:
            returnedOperator = NSLessThanOrEqualToPredicateOperatorType;
            break;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            returnedOperator = NSLessThanPredicateOperatorType;
            break;
        case NSEqualToPredicateOperatorType:
            returnedOperator = NSNotEqualToPredicateOperatorType;
            break;
        case NSNotEqualToPredicateOperatorType:
            returnedOperator = NSEqualToPredicateOperatorType;
            break;
        case NSMatchesPredicateOperatorType:
        case NSLikePredicateOperatorType:
        case NSInPredicateOperatorType:
        case NSContainsPredicateOperatorType:
            returnedOperator = NSContainsPredicateOperatorType; // cannot be handled here
            break;
        case NSBeginsWithPredicateOperatorType:
            returnedOperator = NSBeginsWithPredicateOperatorType; // cannot be handled here
            break;
        case NSEndsWithPredicateOperatorType:
            returnedOperator = NSEndsWithPredicateOperatorType; // cannot be handled here
            break;
        default:
            returnedOperator = NSEqualToPredicateOperatorType;
    }
    
    return returnedOperator;
}

// returns a where clause in an array format for the predicate given.
- (NSArray *)_fetchWhereClauseForComparisonPredicate:(NSPredicate *)aPredicate negate:(BOOL)negate parameterOffset:(int)offset;
{
	if (nil == aPredicate || (![aPredicate isKindOfClass:[NSCompoundPredicate class]] && ![aPredicate isKindOfClass:[NSComparisonPredicate class]])) {
		return nil;
	}
    int parameterOffset = offset;
	id searchObject = [@[[NSMutableString string]] mutableCopy];
    
	if ([aPredicate isKindOfClass:[NSCompoundPredicate class]]) {
        NSCompoundPredicate *predicate = (NSCompoundPredicate *)aPredicate;
		switch ([predicate compoundPredicateType]) {
			case NSNotPredicateType:
            {
				NSArray *result = [self _fetchWhereClauseForComparisonPredicate:[predicate subpredicates][0] negate:!negate parameterOffset:parameterOffset];
                searchObject[0] = result[0];
                [searchObject addObjectsFromArray:[result subarrayWithRange:NSMakeRange(1, result.count-1)]];
				break;
            }
			case NSAndPredicateType:
			{
				NSArray *predicates = [predicate subpredicates];
				for (NSUInteger i=0; i < [predicates count]; i++) {
                    NSArray *result = [self _fetchWhereClauseForComparisonPredicate:[predicate subpredicates][i] negate:negate parameterOffset:parameterOffset];
                    if ([searchObject count] >= 2) {
                        searchObject[0] = [NSString stringWithFormat:@"(%@) AND (%@)", searchObject[0], result[0]];
                    }
                    else {
                        searchObject[0] = result[0];
                    }
                    [searchObject addObjectsFromArray:[result subarrayWithRange:NSMakeRange(1, result.count-1)]];
                    parameterOffset += result.count - 1;
				}
				
			}
				break;
			case NSOrPredicateType:
			{
				NSArray *predicates = [predicate subpredicates];
				for (NSUInteger i=0; i < [predicates count]; i++) {
                    NSArray *result = [self _fetchWhereClauseForComparisonPredicate:[predicate subpredicates][i] negate:negate parameterOffset:parameterOffset];
                    if ([searchObject count] >= 2) {
                        searchObject[0] = [NSString stringWithFormat:@"(%@) OR (%@)", searchObject[0], result[0]];
                    }
                    else {
                        searchObject[0] = result[0];
                    }
                    [searchObject addObjectsFromArray:[result subarrayWithRange:NSMakeRange(1, result.count-1)]];
                    parameterOffset += result.count - 1;
				}
			}
				break;
				
			default:
				break;
		}
		
	}
	else {
		
		NSComparisonPredicate *predicate = (NSComparisonPredicate *)aPredicate;
		NSPredicateOperatorType currentOperator = [predicate predicateOperatorType];
        if (negate) {
            currentOperator = [self _negateOperator:currentOperator];
        }
		// The IN operator type corresponds to "foo contains'f'", but the expressions are reversed to look like "'f' IN foo" so we need a special case
		NSString *attributeName = (currentOperator == NSInPredicateOperatorType) ? [[predicate rightExpression] keyPath] : [[predicate leftExpression] keyPath];
		id searchValue = (currentOperator == NSInPredicateOperatorType) ? [[predicate leftExpression] constantValue] : [[predicate rightExpression] constantValue];
		switch (currentOperator) {
			case NSLessThanPredicateOperatorType:
                searchObject[0] = [NSString stringWithFormat:@"%@ < $%d",attributeName, parameterOffset++];
                [searchObject[1] addObject:searchValue];
				break;
			case NSLessThanOrEqualToPredicateOperatorType:
                searchObject[0] = [NSString stringWithFormat:@"%@ <= $%d",attributeName, parameterOffset++];
                searchObject[1] = searchValue;
				break;
			case NSGreaterThanPredicateOperatorType:
                searchObject[0] = [NSString stringWithFormat:@"%@ > $%d",attributeName, parameterOffset++];
                searchObject[1] = searchValue;
				break;
			case NSGreaterThanOrEqualToPredicateOperatorType:
                searchObject[0] = [NSString stringWithFormat:@"%@ >= $%d",attributeName, parameterOffset++];
                searchObject[1] = searchValue;
    			break;
			case NSEqualToPredicateOperatorType:
                searchObject[0] = [NSString stringWithFormat:@"%@ = $%d",attributeName, parameterOffset++];
                searchObject[1] = searchValue;
				break;
			case NSNotEqualToPredicateOperatorType:
                searchObject[0] = [NSString stringWithFormat:@"%@ <> $%d",attributeName, parameterOffset++];
                searchObject[1] = searchValue;
				break;
			case NSMatchesPredicateOperatorType:
			case NSLikePredicateOperatorType:
			case NSInPredicateOperatorType:
			case NSContainsPredicateOperatorType:
            {
                NSString *operator = (predicate.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
                
                if (negate) {
                    searchObject[0] = [NSString stringWithFormat:@"%@ NOT %@ $%d", attributeName, operator, parameterOffset++];
                }
                else {
                    searchObject[0] = [NSString stringWithFormat:@"%@ %@ $%d",attributeName, operator, parameterOffset++];
                }
                searchObject[1] = [NSString stringWithFormat:@"%%%@%%",searchValue];
            }
                break;
			case NSBeginsWithPredicateOperatorType:
            {
                NSString *operator = (predicate.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
                
                if (negate) {
                    searchObject[0] = [NSString stringWithFormat:@"%@ NOT %@ $%d", attributeName, operator, parameterOffset++];
                }
                else {
                    searchObject[0] = [NSString stringWithFormat:@"%@ %@ $%d",attributeName, operator, parameterOffset++];
                }
                searchObject[1] = [NSString stringWithFormat:@"%@%%",searchValue];
            }
 				break;
			case NSEndsWithPredicateOperatorType:
            {
                NSString *operator = (predicate.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
                
                if (negate) {
                    searchObject[0] = [NSString stringWithFormat:@"%@ NOT %@ $%d", attributeName, operator, parameterOffset++];
                }
                else {
                    searchObject[0] = [NSString stringWithFormat:@"%@ %@ $%d",attributeName, operator, parameterOffset++];
                }
                searchObject[1] = [NSString stringWithFormat:@"%%%@", searchValue];
            }
				break;
            case NSCustomSelectorPredicateOperatorType:
            case NSBetweenPredicateOperatorType:
                break;
		}
	}
	return searchObject;
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
    NSArray *ret = [connection executeSQL:query substitutions:params error:&err];
    if(err) {
        DBDebugLog(@"%@", err);
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
        DBModel *model = [[modelClass alloc] initWithTable:_table id:[row[@"id"] unsignedIntegerValue]];
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