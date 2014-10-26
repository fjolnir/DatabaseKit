#import <Foundation/Foundation.h>
#import <DatabaseKit/DBConnection.h>

typedef NS_ENUM(NSUInteger, DBSQLiteErrorCode)  {
  DBSQLiteDatabaseNotFoundErrorCode = 0
};

@interface DBSQLiteConnection : DBConnection
@property(readonly, retain) NSString *path;
@end
