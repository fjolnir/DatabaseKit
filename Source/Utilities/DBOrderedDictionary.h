#import <Foundation/Foundation.h>

/*! @cond IGNORE */
@interface DBOrderedDictionary : NSMutableDictionary
- (id)objectAtIndex:(NSUInteger)idx;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
@end
/*! @endcond */
