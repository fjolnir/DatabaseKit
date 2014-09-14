#import <Foundation/Foundation.h>

@interface NSPredicate (DBAdditions)
- (NSString *)db_sqlRepresentation:(NSArray **)outParameters;
@end
