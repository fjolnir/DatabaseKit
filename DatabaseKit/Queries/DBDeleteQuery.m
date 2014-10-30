#import "DBQuery+Private.h"
#import "DBDeleteQuery.h"
#import "DBTable.h"
#import "NSPredicate+DBSQLRepresentable.h"

@implementation DBDeleteQuery

- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSParameterAssert(q && p);
    [q appendString:@"DELETE FROM `"];
    [q appendString:[_table toString]];
    [q appendString:@"`"];

    if(_where) {
        [q appendString:@" WHERE "];
        [q appendString:[_where sqlRepresentationForQuery:self withParameters:p]];
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