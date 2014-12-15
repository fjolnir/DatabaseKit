#import "DBDropTableQuery.h"
#import "DBQuery+Private.h"
#import "DBTable.h"

@implementation DBDropTableQuery

- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSParameterAssert(q && p);
    if(!self.table)
        return NO;
    
    [q appendString:@"DROP TABLE `"];
    [q appendString:self.table.name];
    [q appendString:@"`"];

    return YES;
}

@end
