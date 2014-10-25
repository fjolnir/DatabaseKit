#import <DatabaseKit/DBQuery.h>

typedef NS_ENUM(NSUInteger, DBFallback) {
    DBInsertFallbackNone,
    DBInsertFallbackReplace,
    DBInsertFallbackAbort,
    DBInsertFallbackFail,
    DBInsertFallbackIgnore
};
@interface DBInsertQuery : DBWriteQuery <DBTableQuery>
@property(nonatomic, readonly) DBFallback fallback;

- (instancetype)or:(DBFallback)aFallback;
@end

@interface DBUpdateQuery : DBInsertQuery <DBTableQuery, DBFilterableQuery>
@end

@interface DBQuery (DBInsertQuery)
- (DBInsertQuery *)insert:(NSDictionary *)pairs;
@end
@interface DBQuery (DBUpdateQuery)
- (DBUpdateQuery *)update:(NSDictionary *)pairs;
@end
