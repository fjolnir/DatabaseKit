#import "DBQuery.h"

@class DBSelectQuery;

typedef NS_ENUM(NSUInteger, DBFallback) {
    DBInsertFallbackNone,
    DBInsertFallbackReplace,
    DBInsertFallbackAbort,
    DBInsertFallbackFail,
    DBInsertFallbackIgnore
};
@interface DBInsertQuery : DBWriteQuery <DBTableQuery>
@property(readonly) DBFallback fallback;
@property(readonly) DBSelectQuery *sourceQuery;

- (instancetype)or:(DBFallback)aFallback;
@end

@interface DBUpdateQuery : DBInsertQuery <DBTableQuery, DBFilterableQuery>
@end

@interface DBQuery (DBInsertQuery)
- (DBInsertQuery *)insert:(NSDictionary *)pairs;
- (DBInsertQuery *)insertUsingSelect:(DBSelectQuery *)sourceQuery;
- (DBInsertQuery *)insertUsingSelect:(DBSelectQuery *)sourceQuery intoColumns:(NSArray *)columns;
@end
@interface DBQuery (DBUpdateQuery)
- (DBUpdateQuery *)update:(NSDictionary *)pairs;
@end
