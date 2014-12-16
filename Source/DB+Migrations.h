#import <DatabaseKit/DB.h>

@interface DB (Migrations)
- (BOOL)migrateSchema:(NSError **)outErr;
- (BOOL)migrateModelClasses:(NSArray *)classes error:(NSError **)outErr;
@end
