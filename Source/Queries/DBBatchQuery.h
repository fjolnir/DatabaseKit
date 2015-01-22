#import <DatabaseKit/DBQuery.h>

@interface DBBatchQuery : DBWriteQuery
@property(readonly) NSArray *queries;
+ (instancetype)queryWithQueries:(NSArray *)queries;
@end

@interface DBTransactionQuery : DBBatchQuery
@end
