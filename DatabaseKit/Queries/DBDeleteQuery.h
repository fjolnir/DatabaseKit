#import <DatabaseKit/DBQuery.h>

@interface DBDeleteQuery : DBWriteQuery
@end

@interface DBQuery (DBDeleteQuery)
- (DBDeleteQuery *)delete;
@end
