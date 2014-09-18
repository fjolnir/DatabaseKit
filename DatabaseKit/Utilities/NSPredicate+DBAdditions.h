#import <Foundation/Foundation.h>

@interface NSPredicate (DBAdditions)
- (NSString *)db_sqlRepresentation:(NSMutableArray *)parameters;
@end
