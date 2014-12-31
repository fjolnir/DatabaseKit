#import "NSPredicate+DBSQLRepresentable.h"
#import "DB.h"
#import "DBTable.h"
#import "DBQuery.h"

@implementation NSPredicate (DBSQLRepresentable)

- (NSString *)sqlRepresentationForQuery:(DBQuery *)query withParameters:(NSMutableArray *)parameters
{
    return [self _sqlRepresentationForQuery:query withParameters:parameters negate:NO];

}

- (NSString *)_sqlRepresentationForQuery:(DBQuery *)query
                          withParameters:(NSMutableArray *)parameters
                                  negate:(BOOL)negate
{
    return nil;
}

@end

@implementation NSCompoundPredicate (DBSQLRepresentable)

- (NSString *)_sqlRepresentationForQuery:(DBQuery *)query
                             withParameters:(NSMutableArray *)parameters
                                     negate:(BOOL)negate
{
    switch([self compoundPredicateType]) {
        case NSNotPredicateType:
            return [self.subpredicates[0] _sqlRepresentationForQuery:query
                                                         withParameters:parameters
                                                                 negate:!negate];
        case NSAndPredicateType: {
            __block NSString *sql = nil;
            [self.subpredicates enumerateObjectsUsingBlock:^(NSPredicate *subPredicate, NSUInteger idx, BOOL *stop) {
                NSString *subSql = [subPredicate _sqlRepresentationForQuery:query
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
                NSString *subSql = [subPredicate _sqlRepresentationForQuery:query
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

@interface NSExpression (DBSQLRepresentable)
- (NSString *)_sqlRepresentationForQuery:(DBQuery *)query
                             withParameters:(NSMutableArray *)parameters;
@end

@implementation NSExpression (DBSQLRepresentable)

- (NSString *)_sqlRepresentationForQuery:(DBQuery<DBTableQuery> *)query
                             withParameters:(NSMutableArray *)parameters
{
    switch(self.expressionType) {
        case NSKeyPathExpressionType: {
            NSMutableString *quotedKeyPath = [NSMutableString stringWithFormat:@"`%@`", self.keyPath];
            [quotedKeyPath replaceOccurrencesOfString:@"." withString:@"`.`"
                                              options:0
                                                range:(NSRange) { 0, [quotedKeyPath length] }];
            if(query.table && [self.keyPath rangeOfString:@"."].location == NSNotFound) {
                [quotedKeyPath insertString:@"." atIndex:0];
                [quotedKeyPath insertString:query.table.name atIndex:0];
            }
            return quotedKeyPath;
        } case NSConstantValueExpressionType:
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
        default:
            [NSException raise:NSInternalInconsistencyException
                        format:@"Expression '%@' does not support SQL generation", self];
            return nil;
    }
}

@end

@implementation NSComparisonPredicate (DBSQLRepresentable)

- (NSString *)_sqlRepresentationForQuery:(DBQuery<DBTableQuery> *)query
                             withParameters:(NSMutableArray *)parameters
                                     negate:(BOOL)negate
{
    NSPredicateOperatorType operator = negate
                                     ? [self _negateOperator:[self predicateOperatorType]]
                                     : [self predicateOperatorType];

    switch(operator) {
        case NSLessThanPredicateOperatorType:
            return [NSString stringWithFormat:@"%@ < %@",
                    [self.leftExpression _sqlRepresentationForQuery:query withParameters:parameters],
                    [self.rightExpression _sqlRepresentationForQuery:query withParameters:parameters]];
        case NSLessThanOrEqualToPredicateOperatorType:
            return [NSString stringWithFormat:@"%@ <= %@",
                    [self.leftExpression _sqlRepresentationForQuery:query withParameters:parameters],
                    [self.rightExpression _sqlRepresentationForQuery:query withParameters:parameters]];
        case NSGreaterThanPredicateOperatorType:
            return [NSString stringWithFormat:@"%@ > %@",
                    [self.leftExpression _sqlRepresentationForQuery:query withParameters:parameters],
                    [self.rightExpression _sqlRepresentationForQuery:query withParameters:parameters]];
        case NSGreaterThanOrEqualToPredicateOperatorType:
            return [NSString stringWithFormat:@"%@ >= %@",
                    [self.leftExpression _sqlRepresentationForQuery:query withParameters:parameters],
                    [self.rightExpression _sqlRepresentationForQuery:query withParameters:parameters]];
        case NSEqualToPredicateOperatorType:
            return [NSString stringWithFormat:@"%@ IS %@",
                    [self.leftExpression _sqlRepresentationForQuery:query withParameters:parameters],
                    [self.rightExpression _sqlRepresentationForQuery:query withParameters:parameters]];
        case NSNotEqualToPredicateOperatorType:
            return [NSString stringWithFormat:@"%@ IS NOT %@",
                    [self.leftExpression _sqlRepresentationForQuery:query withParameters:parameters],
                    [self.rightExpression _sqlRepresentationForQuery:query withParameters:parameters]];
        case NSInPredicateOperatorType: {
            return [NSString stringWithFormat:negate ? @"%@ NOT IN (%@)" : @"%@ IN (%@)",
                    [self.leftExpression _sqlRepresentationForQuery:query withParameters:parameters],
                    [self.rightExpression _sqlRepresentationForQuery:query withParameters:parameters]];
        } case NSLikePredicateOperatorType: {
            NSAssert(self.rightExpression.expressionType == NSConstantValueExpressionType &&
                     [self.rightExpression.constantValue isKindOfClass:[NSString class]],
                     @"LIKE can only have a constant string as a right expression");

            NSString *pattern = [self.rightExpression.constantValue stringByReplacingOccurrencesOfString:@"*"
                                                                                              withString:@"%"];
            pattern = [pattern stringByReplacingOccurrencesOfString:@"?" withString:@"_"];
            NSString *likeOperator = (self.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
            
            return [NSString stringWithFormat:(negate ? @"%@ NOT %@ %@" : @"%@ %@ %@"),
                                              [self.leftExpression _sqlRepresentationForQuery:query withParameters:parameters],
                                              likeOperator,
                                              [[NSExpression expressionForConstantValue:pattern] _sqlRepresentationForQuery:query withParameters:parameters]];
        }
        case NSBeginsWithPredicateOperatorType: {
            NSString *likeOperator = (self.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";

            if(!(self.options & NSCaseInsensitivePredicateOption) &&
               self.leftExpression.expressionType == NSKeyPathExpressionType &&
               self.rightExpression.expressionType == NSConstantValueExpressionType &&
               [self.rightExpression.constantValue isKindOfClass:[NSString class]] &&
               [self.rightExpression.constantValue length] > 0)
            {
                // If case is not an issue we can express this as an inequality which will make use of indices
                // But only if the column being checked against is of a textual type
                NSUInteger dotIdx = [self.leftExpression.keyPath rangeOfString:@"."].location;
                DBTable   * table = (dotIdx == NSNotFound || [self.leftExpression.keyPath hasPrefix:[query.table.name stringByAppendingString:@"."]])
                                  ? query.table
                                  : query.table.database[[self.leftExpression.keyPath substringToIndex:dotIdx]];
                NSString  *column = dotIdx == NSNotFound
                                  ? self.leftExpression.keyPath
                                  : [self.leftExpression.keyPath substringFromIndex:dotIdx+1];

                if([table typeOfColumn:column] == DBTypeText) {
                    NSString * const prefix      = self.rightExpression.constantValue;
                    unichar const incremented    = [prefix characterAtIndex:[prefix length] - 1] + 1;
                    NSString * const upperBounds = [prefix
                                                    stringByReplacingCharactersInRange:(NSRange) { [prefix length] - 1, 1 }
                                                    withString:[NSString stringWithCharacters:&incremented length:1]];
                    NSString * const left  = [self.leftExpression _sqlRepresentationForQuery:query withParameters:parameters],
                             * const right = [self.rightExpression _sqlRepresentationForQuery:query withParameters:parameters],
                      * const rightPlusOne = [[NSExpression expressionForConstantValue:upperBounds] _sqlRepresentationForQuery:query
                                                                                                                   withParameters:parameters];
                    return [NSString stringWithFormat:negate ? @"(%@ < %@) OR (%@ >= %@)" : @"(%@ >= %@) AND (%@ < %@)",
                            left, right, left, rightPlusOne];
                }
            }
            return [NSString stringWithFormat:(negate ? @"%@ NOT %@ %@||'%%'" : @"%@ %@ %@||'%%'"),
                                              [self.leftExpression _sqlRepresentationForQuery:query withParameters:parameters],
                                              likeOperator,
                                              [self.rightExpression _sqlRepresentationForQuery:query withParameters:parameters]];
        }
        case NSEndsWithPredicateOperatorType: {
            NSString *likeOperator = (self.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
            return [NSString stringWithFormat:(negate ? @"%@ NOT %@ '%%'||%@" : @"%@ %@ '%%'||%@"),
                                              [self.leftExpression _sqlRepresentationForQuery:query withParameters:parameters],
                                              likeOperator,
                                              [self.rightExpression _sqlRepresentationForQuery:query withParameters:parameters]];
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
