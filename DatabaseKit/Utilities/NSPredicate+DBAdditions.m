#import "NSPredicate+DBAdditions.h"

@implementation NSPredicate (DBAdditions)

- (NSString *)db_sqlRepresentation:(NSMutableArray *)parameters
{
    return [self _db_sqlRepresentationWithParameters:parameters negate:NO];

}

- (NSString *)_db_sqlRepresentationWithParameters:(NSMutableArray *)aParameters
                                           negate:(BOOL)negate
{
    return nil;
}

@end

@implementation NSCompoundPredicate (DBAdditions)

- (NSString *)_db_sqlRepresentationWithParameters:(NSMutableArray *)aParameters
                                           negate:(BOOL)negate
{
    switch([self compoundPredicateType]) {
        case NSNotPredicateType:
            return [self.subpredicates[0] _db_sqlRepresentationWithParameters:aParameters
                                                                       negate:!negate];
        case NSAndPredicateType: {
            __block NSString *sql = nil;
            [self.subpredicates enumerateObjectsUsingBlock:^(NSPredicate *subPredicate, NSUInteger idx, BOOL *stop) {
                NSString *subSql = [subPredicate _db_sqlRepresentationWithParameters:aParameters
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
                NSString *subSql = [subPredicate _db_sqlRepresentationWithParameters:aParameters
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

@implementation NSComparisonPredicate (DBAdditions)

- (NSString *)_db_sqlRepresentationWithParameters:(NSMutableArray *)parameters
                                           negate:(BOOL)negate
{
    NSPredicateOperatorType operator = negate
                                     ? [self _negateOperator:[self predicateOperatorType]]
                                     : [self predicateOperatorType];

    switch(operator) {
        case NSLessThanPredicateOperatorType:
            [parameters addObject:self.rightExpression.constantValue];
            return  [NSString stringWithFormat:@"%@ < $%d", self.leftExpression.keyPath, [parameters count]];
        case NSLessThanOrEqualToPredicateOperatorType:
            [parameters addObject:self.rightExpression.constantValue];
            return  [NSString stringWithFormat:@"%@ <= $%d", self.leftExpression.keyPath, [parameters count]];
        case NSGreaterThanPredicateOperatorType:
            [parameters addObject:self.rightExpression.constantValue];
            return  [NSString stringWithFormat:@"%@ > $%d", self.leftExpression.keyPath, [parameters count]];
        case NSGreaterThanOrEqualToPredicateOperatorType:
            [parameters addObject:self.rightExpression.constantValue];
            return  [NSString stringWithFormat:@"%@ >= $%d", self.leftExpression.keyPath, [parameters count]];
        case NSEqualToPredicateOperatorType:
            [parameters addObject:self.rightExpression.constantValue];
            return  [NSString stringWithFormat:@"%@ IS $%d", self.leftExpression.keyPath, [parameters count]];
        case NSNotEqualToPredicateOperatorType:
            [parameters addObject:self.rightExpression.constantValue];
            return [NSString stringWithFormat:@"%@ <> $%d", self.leftExpression.keyPath, [parameters count]];
        case NSInPredicateOperatorType: {
            NSMutableArray *tokens = [NSMutableArray new];
            NSArray *options = self.rightExpression.constantValue;
            for(unsigned long i = [parameters count] + 1; i < [parameters count] + [options count]; ++i) {
                [tokens addObject:[NSString stringWithFormat:@"$%lu", i]];
            }
            [parameters addObjectsFromArray:options];
            return [NSString stringWithFormat:@"%@ IN (%@)",
                                              self.leftExpression.keyPath,
                                              [tokens componentsJoinedByString:@", "]];
        } case NSLikePredicateOperatorType: {
            [parameters addObject:[NSString stringWithFormat:@"%%%@%%", self.rightExpression.constantValue]];
            NSString *operator = (self.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
            return [NSString stringWithFormat:(negate ? @"%@ NOT %@ $%d" : @"%@ %@ $%d"),
                                              self.leftExpression.keyPath, operator, [parameters count]];
        }
        case NSBeginsWithPredicateOperatorType: {
            [parameters addObject:[NSString stringWithFormat:@"%@%%",self.rightExpression.constantValue]];
            NSString *operator = (self.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
            return [NSString stringWithFormat:(negate ? @"%@ NOT %@ $%d" : @"%@ %@ $%d"),
                                              self.leftExpression.keyPath, operator, [parameters count]];
        }
        case NSEndsWithPredicateOperatorType: {
            [parameters addObject:[NSString stringWithFormat:@"%%%@",self.rightExpression.constantValue]];
            NSString *operator = (self.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
            return [NSString stringWithFormat:(negate ? @"%@ NOT %@ $%d" : @"%@ %@ $%d"),
                                              self.leftExpression.keyPath, operator, [parameters count]];
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
