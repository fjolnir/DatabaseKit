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
            [parameters addObject:value];
            return  [NSString stringWithFormat:@"%@ < $%lu",
                     self.leftExpression.keyPath, (unsigned long)[parameters count]];
        case NSLessThanOrEqualToPredicateOperatorType:
            [parameters addObject:value];
            return  [NSString stringWithFormat:@"%@ <= $%lu",
                     self.leftExpression.keyPath, (unsigned long)[parameters count]];
        case NSGreaterThanPredicateOperatorType:
            [parameters addObject:value];
            return  [NSString stringWithFormat:@"%@ > $%lu",
                     self.leftExpression.keyPath, (unsigned long)[parameters count]];
        case NSGreaterThanOrEqualToPredicateOperatorType:
            [parameters addObject:value];
            return  [NSString stringWithFormat:@"%@ >= $%lu",
                     self.leftExpression.keyPath, (unsigned long)[parameters count]];
        case NSEqualToPredicateOperatorType:
            [parameters addObject:value];
            return  [NSString stringWithFormat:@"%@ IS $%lu",
                     self.leftExpression.keyPath, (unsigned long)[parameters count]];
        case NSNotEqualToPredicateOperatorType:
            [parameters addObject:value];
            return [NSString stringWithFormat:@"%@ IS NOT $%lu",
                    self.leftExpression.keyPath, (unsigned long)[parameters count]];
        case NSInPredicateOperatorType: {
            NSMutableArray *tokens = [NSMutableArray new];
            NSArray *options = self.rightExpression.constantValue;
            for(unsigned long i = [parameters count]; i < [parameters count] + [options count]; ++i) {
                [tokens addObject:[NSString stringWithFormat:@"$%lu", i+1]];
            }
            [parameters addObjectsFromArray:options];
            return [NSString stringWithFormat:negate ? @"%@ NOT IN (%@)" : @"%@ IN (%@)",
                                              self.leftExpression.keyPath,
                                              [tokens componentsJoinedByString:@", "]];
        } case NSLikePredicateOperatorType: {
            if([value isKindOfClass:[NSString class]]) {
                value = [value stringByReplacingOccurrencesOfString:@"*" withString:@"%"];
                value = [value stringByReplacingOccurrencesOfString:@"?" withString:@"_"];
            }
            [parameters addObject:value];
            NSString *operator = (self.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
            return [NSString stringWithFormat:(negate ? @"%@ NOT %@ $%lu" : @"%@ %@ $%lu"),
                                              self.leftExpression.keyPath, operator, (unsigned long)[parameters count]];
        }
        case NSBeginsWithPredicateOperatorType: {
            [parameters addObject:[NSString stringWithFormat:@"%@%%",self.rightExpression.constantValue]];
            NSString *operator = (self.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
            return [NSString stringWithFormat:(negate ? @"%@ NOT %@ $%lu" : @"%@ %@ $%lu"),
                                              self.leftExpression.keyPath, operator, (unsigned long)[parameters count]];
        }
        case NSEndsWithPredicateOperatorType: {
            [parameters addObject:[NSString stringWithFormat:@"%%%@",self.rightExpression.constantValue]];
            NSString *operator = (self.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
            return [NSString stringWithFormat:(negate ? @"%@ NOT %@ $%lu" : @"%@ %@ $%lu"),
                                              self.leftExpression.keyPath, operator, (unsigned long)[parameters count]];
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
