#import <Foundation/Foundation.h>

@class DBConnection, DBTable, DBCreateTableQuery;

@interface DB : NSObject
@property(readonly, strong) DBConnection *connection;

+ (DB *)withURL:(NSURL *)URL;
+ (DB *)withURL:(NSURL *)URL error:(NSError **)err;

- (id)initWithConnection:(DBConnection *)aConnection;

// Returns a table whose name matches key or nil
- (DBTable *)objectForKeyedSubscript:(id)key;

- (DBCreateTableQuery *)create;
@end

@class DBModel;
@interface DB (DBModel)
- (BOOL)saveDirtyObjects:(NSError **)outErr;
@end

@interface DB (DBModelPrivate)
- (void)registerDirtyObject:(DBModel *)obj;
@end
