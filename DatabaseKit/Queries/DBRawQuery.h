#import "DBQuery.h"

@interface DBRawQuery : DBQuery
@property(readonly, strong) NSString *SQL;
@end
