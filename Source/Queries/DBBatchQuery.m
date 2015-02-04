#import "DBBatchQuery.h"
#import "DB.h"

@interface DBAtEndResult : DBResult
+ (instancetype)sharedResult;
@end

@implementation DBBatchQuery
+ (instancetype)queryWithQueries:(NSArray *)queries
{
    NSParameterAssert(queries.count > 0);
    DBBatchQuery *query = [self new];
    if(query)
        query->_queries = queries;
    return query;
}

- (DBResult *)rawExecuteOnConnection:(DBConnection *)connection error:(NSError *__autoreleasing *)outErr
{
    for(DBWriteQuery *query in _queries) {
        NSAssert([query isKindOfClass:[DBWriteQuery class]],
                 @"Batch queries can only consist of write queries");
        
        if(![query executeOnConnection:connection error:outErr])
            return nil;
    }
    return [DBAtEndResult sharedResult];
}
- (DBConnection *)connection
{
    return [[(DBWriteQuery *)_queries.firstObject database] connection];
}
@end

@implementation DBTransactionQuery
- (DBResult *)rawExecuteOnConnection:(DBConnection *)connection error:(NSError *__autoreleasing *)outErr
{
    __block DBResult *result;
    BOOL successful = [connection transaction:^{
        result = [super rawExecuteOnConnection:connection error:outErr];
        return [result step:outErr] == DBResultStateAtEnd
               ? DBTransactionCommit
               : DBTransactionRollBack;
    } error:outErr];
    return successful ? result : nil;
}
@end

@implementation DBAtEndResult
+ (instancetype)sharedResult
{
    static DBAtEndResult *result;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = [self new];
        result->_state = DBResultStateAtEnd;
    });
    return result;
}
- (DBResultState)step:(NSError **)outErr
{
    return _state;
}
- (NSUInteger)columnCount
{
    return 0;
}
@end
