#import <Foundation/Foundation.h>

@interface DBOrderedDictionary : NSMutableDictionary
- (id)objectAtIndex:(NSUInteger)idx;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
@end
