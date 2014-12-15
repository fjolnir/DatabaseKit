#import <Foundation/Foundation.h>

@interface DBOrderedDictionary : NSMutableDictionary
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
@end
