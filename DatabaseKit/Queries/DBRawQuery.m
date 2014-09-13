#import "DBRawQuery.h"

@interface DBRawQuery ()
@property(readwrite, strong) NSString *SQL;
@end

@implementation DBRawQuery
- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    [q setString:_SQL];
    return YES;
}
@end
