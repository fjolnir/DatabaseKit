#import <Foundation/Foundation.h>

@class DBQuery;

@interface NSPredicate (DBAdditions)
- (NSString *)db_sqlRepresentationForQuery:(DBQuery *)query withParameters:(NSMutableArray *)parameters;
@end
