#import "DBQuery+Private.h"
#import "DBDeleteQuery.h"
#import "DBTable.h"

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

@implementation DBQuery (DBDeleteQuery)
- (DBDeleteQuery *)delete
{
    DBDeleteQuery *ret = [self _copyWithSubclass:[DBDeleteQuery class]];
    ret.fields = nil;
    return ret;
}
@end