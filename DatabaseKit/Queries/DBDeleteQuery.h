#import <DatabaseKit/DBQuery.h>

@interface DBDeleteQuery : DBWriteQuery <DBTableQuery, DBFilterableQuery>
@end

@interface DBQuery (DBDeleteQuery)
- (DBDeleteQuery *)delete;
@end
