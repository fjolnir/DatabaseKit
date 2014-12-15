#import "DB.h"

@interface DB (Migrations)
- (BOOL)migrateModelClasses:(NSArray *)classes error:(NSError **)outErr;
@end
