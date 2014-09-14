#import <DatabaseKit/Queries/DBQuery.h>

typedef NS_ENUM(NSUInteger, DBFallback) {
    DBInsertFallbackNone,
    DBInsertFallbackReplace,
    DBInsertFallbackAbort,
    DBInsertFallbackFail,
    DBInsertFallbackIgnore
};
@interface DBInsertQuery : DBQuery
@property(nonatomic, readonly) DBFallback fallback;

- (instancetype)or:(DBFallback)aFallback;
@end

@interface DBUpdateQuery : DBInsertQuery
@end
