#import "NSPredicate+DBAdditions.h"

@implementation NSPredicate (DBAdditions)

- (NSString *)db_sqlRepresentation:(NSArray **)outParameters
{
    NSMutableArray *parameters = [NSMutableArray new];
    if(outParameters)
        *outParameters = parameters;
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
    NSString *sql = nil;

    NSCompoundPredicate *predicate = (id)self;
    NSArray *subPredicates = [predicate subpredicates];
    switch ([predicate compoundPredicateType]) {
        case NSNotPredicateType:
        {
            sql = [subPredicates[0] _db_sqlRepresentationWithParameters:aParameters
                                                                 negate:!negate];
            break;
        }
        case NSAndPredicateType:
        {
            for (NSUInteger i=0; i < [subPredicates count]; i++) {
                NSString *subSql = [subPredicates[i] _db_sqlRepresentationWithParameters:aParameters
                                                                                  negate:negate];
                sql = [sql length] == 0
                    ? subSql
                    : [NSString stringWithFormat:@"(%@) AND (%@)", sql, subSql];
            }
            
        }
            break;
        case NSOrPredicateType:
        {
            for (NSUInteger i=0; i < [subPredicates count]; i++) {
                NSString *subSql = [subPredicates[i] _db_sqlRepresentationWithParameters:aParameters
                                                                                  negate:negate];
                sql = [sql length] == 0
                    ? subSql
                    : [NSString stringWithFormat:@"(%@) OR (%@)", sql, subSql];
            }
        }
    }
	return sql;
}
@end

@implementation NSComparisonPredicate (DBAdditions)

- (NSString *)_db_sqlRepresentationWithParameters:(NSMutableArray *)parameters
                                           negate:(BOOL)negate
{
    NSPredicateOperatorType operator = negate
                                     ? [self _negateOperator:[self predicateOperatorType]]
                                     : [self predicateOperatorType];

    // The IN operator type corresponds to "foo contains'f'", but the expressions are reversed to look like "'f' IN foo" so we need a special case
    NSString *attributeName = self.leftExpression.keyPath;

    id searchValue = self.rightExpression.constantValue;
    switch(operator) {
        case NSLessThanPredicateOperatorType:
            [parameters addObject:searchValue];
            return  [NSString stringWithFormat:@"%@ < $%d", attributeName, [parameters count]];
        case NSLessThanOrEqualToPredicateOperatorType:
            [parameters addObject:searchValue];
            return  [NSString stringWithFormat:@"%@ <= $%d", attributeName, [parameters count]];
        case NSGreaterThanPredicateOperatorType:
            [parameters addObject:searchValue];
            return  [NSString stringWithFormat:@"%@ > $%d", attributeName, [parameters count]];
        case NSGreaterThanOrEqualToPredicateOperatorType:
            [parameters addObject:searchValue];
            return  [NSString stringWithFormat:@"%@ >= $%d", attributeName, [parameters count]];
        case NSEqualToPredicateOperatorType:
            [parameters addObject:searchValue];
            return  [NSString stringWithFormat:@"%@ = $%d", attributeName, [parameters count]];
        case NSNotEqualToPredicateOperatorType:
            [parameters addObject:searchValue];
            return [NSString stringWithFormat:@"%@ <> $%d", attributeName, [parameters count]];
        case NSInPredicateOperatorType: {
            NSMutableArray *tokens = [NSMutableArray new];
            for(unsigned long i = [parameters count] + 1; i < [parameters count] + [searchValue count]; ++i) {
                [tokens addObject:[NSString stringWithFormat:@"$%lu", i]];
            }
            [parameters addObjectsFromArray:searchValue];
            return [NSString stringWithFormat:@"%@ IN (%@)", attributeName, [tokens componentsJoinedByString:@", "]];
            NSMutableArray *comparisons = [NSMutableArray new];
            for(id value in searchValue) {
                [comparisons addObject:[NSComparisonPredicate
                                        predicateWithLeftExpression:[self leftExpression]
                                        rightExpression:[NSExpression expressionForConstantValue:value]
                                        modifier:NSDirectPredicateModifier
                                        type:NSEqualToPredicateOperatorType
                                        options:0]];
            }
            return [[NSCompoundPredicate orPredicateWithSubpredicates:comparisons]
                    _db_sqlRepresentationWithParameters:parameters
                    negate:negate];
        } case NSLikePredicateOperatorType: {
            [parameters addObject:[NSString stringWithFormat:@"%%%@%%", searchValue]];
            NSString *operator = (self.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
            return negate
                ? [NSString stringWithFormat:@"%@ NOT %@ $%d", attributeName, operator, [parameters count]]
                : [NSString stringWithFormat:@"%@ %@ $%d",attributeName, operator, [parameters count]];
        }
        case NSBeginsWithPredicateOperatorType: {
            [parameters addObject:[NSString stringWithFormat:@"%@%%",searchValue]];
            NSString *operator = (self.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";

            return negate
                 ? [NSString stringWithFormat:@"%@ NOT %@ $%d", attributeName, operator, [parameters count]]
                 : [NSString stringWithFormat:@"%@ %@ $%d",attributeName, operator, [parameters count]];
        }
        case NSEndsWithPredicateOperatorType: {
            [parameters addObject:[NSString stringWithFormat:@"%%%@",searchValue]];
            NSString *operator = (self.options & NSCaseInsensitivePredicateOption) ? @"ILIKE" : @"LIKE";
            
            return negate
                 ? [NSString stringWithFormat:@"%@ NOT %@ $%d", attributeName, operator, [parameters count]]
                 : [NSString stringWithFormat:@"%@ %@ $%d",attributeName, operator, [parameters count]];
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
