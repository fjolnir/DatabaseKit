#import <Foundation/Foundation.h>

@class DBQuery;

@protocol DBSQLRepresentable <NSObject>
/*!
 * Returns the sql representation of self, for `query` appending any parameters required to the passed mutable array
 */
- (NSString *)sqlRepresentationForQuery:(DBQuery *)query withParameters:(NSMutableArray *)parameters;
@end
