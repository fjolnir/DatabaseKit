#import "NSPredicate+DBAdditions.h"
#import "DBTable.h"
#import "DBQuery.h"

@implementation NSPredicate (DBAdditions)

- (NSString *)db_sqlRepresentationForQuery:(DBQuery *)query withParameters:(NSMutableArray *)parameters
{
    return [self _db_sqlRepresentationForQuery:query withParameters:parameters negate:NO];

}

- (NSString *)_db_sqlRepresentationForQuery:(DBQuery *)query
                             withParameters:(NSMutableArray *)parameters
                                     negate:(BOOL)negate
{
    return nil;
}

@end

@implementation NSCompoundPredicate (DBAdditions)

- (NSString *)_db_sqlRepresentationForQuery:(DBQuery *)query
                             withParameters:(NSMutableArray *)parameters
                                     negate:(BOOL)negate
{
    switch([self compoundPredicateType]) {
        case NSNotPredicateType:
            return [self.subpredicates[0] _db_sqlRepresentationForQuery:query
                                                         withParameters:parameters
                                                                 negate:!negate];
        case NSAndPredicateType: {
            __block NSString *sql = nil;
            [self.subpredicates enumerateObjectsUsingBlock:^(NSPredicate *subPredicate, NSUInteger idx, BOOL *stop) {
                NSString *subSql = [subPredicate _db_sqlRepresentationForQuery:query
                                                                withParameters:parameters
                                                                        negate:negate];
                sql = !sql
                    ? subSql
                    : [NSString stringWithFormat:@"(%@) AND (%@)", sql, subSql];
            }];
            return sql;
        }
            break;
        case NSOrPredicateType: {
            __block NSString *sql = nil;
            [self.subpredicates enumerateObjectsUsingBlock:^(NSPredicate *subPredicate, NSUInteger idx, BOOL *stop) {
                NSString *subSql = [subPredicate _db_sqlRepresentationForQuery:query
                                                                withParameters:parameters
                                                                        negate:negate];
                sql = !sql
                    ? subSql
                    : [NSString stringWithFormat:@"(%@) OR (%@)", sql, subSql];
            }];
            return sql;
        }
        default:
            return nil;
    }
}

@end

@interface NSExpression (DBAdditions)
- (NSString *)_db_sqlRepresentationForQuery:(DBQuery *)query
                             withParameters:(NSMutableArray *)parameters;
@end

@implementation NSExpression (DBAdditions)

- (NSString *)_db_sqlRepresentationForQuery:(DBQuery *)query
                             withParameters:(NSMutableArray *)parameters
{
    switch(self.expressionType) {
        case NSKeyPathExpressionType:
            if(query.table && [self.keyPath rangeOfString:@"."].location == NSNotFound)
                return [query.table.name stringByAppendingFormat:@".%@", self.keyPath];
            else
                return self.keyPath;
            break;
        case NSConstantValueExpressionType:
            if([self.constantValue isKindOfClass:[NSArray class]]) {
                NSMutableArray *bindings = [NSMutableArray new];
                for(NSUInteger i = 1; i <= [self.constantValue count]; ++i) {
                    [bindings addObject:[NSString stringWithFormat:@"$%lu", (unsigned long)(i + [parameters count])]];
                }
                [parameters addObjectsFromArray:self.constantValue];
                return [bindings componentsJoinedByString:@", "];
            } else {
                [parameters addObject:self.constantValue ?: [NSNull null]];
                return [NSString stringWithFormat:@"$%lu", (unsigned long)(parameters ? [parameters count] : 1)];
            }
            break;
        default:
            [NSException raise:NSInternalInconsistencyException
                        format:@"Expression '%@' does not support SQL generation", self];
            return nil;
    }
}

@end

@implementation NSComparisonPredicate (DBAdditions)

- (NSString *)_db_sqlRepresentationForQuery:(DBQuery *)query
                             withParameters:(NSMutableArray *)parameters
                                     negate:(BOOL)negate
{
    NSPredicateOperatorType operator = negate
                                     ? [self _negateOperator:[self predicateOperatorType]]
                                     : [self predicateOperatorType];

    id value = self.rightExpression.constantValue ?: [NSNull null];
    switch(operator) {
        case NSLessThanPredicateOperatorType:
            return [NSString stringWithFormat:@"%@ < %@",
                    [self.leftExpression _db_sqlRepresentationForQuery:query withParameters:parameters],
                    [self.rightExpression _db_sqlRepresentationForQuery:query withParameters:parameters]];
        case NSLessThanOrEqualToPredicateOperatorType:
            return [NSString stringWithFormat:@"%@ <= %@",
                    [self.leftExpression _db_sqlRepresentationForQuery:query withParameters:parameters],
                    [self.rightExpression _db_sqlRepresentationForQuery:query withParameters:parameters]];
        case NSGreaterThanPredicateOperatorType:
            return [NSString stringWithFormat:@"%@ > %@",
                    [self.leftExpression _db_sqlRepresentationForQuery:query withParameters:parameters],
                    [self.rightExpression _db_sqlRepresentationForQuery:query withParameters:parameters]];
        case NSGreaterThanOrEqualToPredicateOperatorType:
            return [NSString stringWithFormat:@"%@ >= %@",
                    [self.leftExpression _db_sqlRepresentationForQuery:query withParameters:parameters],
                    [self.rightExpression _db_sqlRepresentationForQuery:query withParameters:parameters]];
        case NSEqualToPredicateOperatorType:
            return [NSString stringWithFormat:@"%@ IS %@",
                    [self.leftExpression _db_sqlRepresentationForQuery:query withParameters:parameters],
                    [self.rightExpression _db_sqlRepresentationForQuery:query withParameters:parameters]];
        case NSNotEqualToPredicateOperatorType:
            return [NSString stringWithFormat:@"%@ IS NOT %@",
                    [self.leftExpression _db_sqlRepresentationForQuery:query withParameters:parameters],
                    [self.rightExpression _db_sqlRepresentationForQuery:query withParameters:parameters]];
        case NSInPredicateOperatorType: {
            return [NSString stringWithFormat:negate ? @"%@ NOT IN (%@)" : @"%@ IN (%@)",
                    [self.leftExpression _db_sqlRepresentationForQuery:query withParameters:parameters],
                    [self.rightExpression _db_sqlRepresentationForQuery:query withParameters:parameters]];
        } case NSLikePredicateOperatorType: {
            NSAssert(self.rightExpression.expressionType == NSConstantValueExpressionType &&
                     [self.rightExpression.constantValue isKindOfClass:[NSString class]],
                     @"LIKE can only have a constant string as a right expression");

            NSString *pattern = [self.rightExpression.constantValue stringByReplacingOccurrencesOfString:@"*"
                                                                                              withString:@"%"];
            pattern = [pattern stringByReplacingOccurrencesOfString:@"?" withString:@"_"];
            NSString *operator = (self.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
            
            return [NSString stringWithFormat:(negate ? @"%@ NOT %@ %@" : @"%@ %@ %@"),
                                              [self.leftExpression _db_sqlRepresentationForQuery:query withParameters:parameters],
                                              operator,
                                              [[NSExpression expressionForConstantValue:pattern] _db_sqlRepresentationForQuery:query withParameters:parameters]];
        }
        case NSBeginsWithPredicateOperatorType: {
            [parameters addObject:[NSString stringWithFormat:@"%@%%",self.rightExpression.constantValue]];
            NSString *operator = (self.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
            return [NSString stringWithFormat:(negate ? @"%@ NOT %@ $%lu" : @"%@ %@ $%lu"),
                                              self.leftExpression.keyPath, operator, (unsigned long)[parameters count]];
        }
        case NSEndsWithPredicateOperatorType: {
            NSString *operator = (self.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
            return [NSString stringWithFormat:(negate ? @"%@ NOT %@ '%%'||%@" : @"%@ %@ '%%'||%@"),
                                              [self.leftExpression _db_sqlRepresentationForQuery:query withParameters:parameters],
                                              operator,
                                              [self.rightExpression _db_sqlRepresentationForQuery:query withParameters:parameters]];
        }
        default:
            return nil;
    }
}

- (NSPredicateOperatorType)_negateOperator:(NSPredicateOperatorType)aOperator;
{
    switch(aOperator) {
        case NSLessThanPredicateOperatorType:
            return NSGreaterThanOrEqualToPredicateOperatorType;
        case NSLessThanOrEqualToPredicateOperatorType:
            return NSGreaterThanPredicateOperatorType;
        case NSGreaterThanPredicateOperatorType:
            return NSLessThanOrEqualToPredicateOperatorType;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            return NSLessThanPredicateOperatorType;
        case NSEqualToPredicateOperatorType:
            return NSNotEqualToPredicateOperatorType;
        case NSNotEqualToPredicateOperatorType:
            return NSEqualToPredicateOperatorType;
        default:
            return aOperator; // Not handled here
    }
}

@end
