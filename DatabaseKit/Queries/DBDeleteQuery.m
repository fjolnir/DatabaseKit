#import "DBQuery+Private.h"
#import "DBDeleteQuery.h"
#import "DBTable.h"
#import "NSPredicate+DBAdditions.h"

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

    if(_where) {
        [q appendString:@" WHERE "];
        [q appendString:[_where db_sqlRepresentationForQuery:self withParameters:p]];
    }

    return YES;
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