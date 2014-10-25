#import <Foundation/Foundation.h>
#import <DatabaseKit/DBConnection.h>

typedef enum  {
  DBSQLiteDatabaseNotFoundErrorCode = 0
} DBSQLiteErrorCode;

@interface DBSQLiteConnection : DBConnection
@property(readonly, retain) NSString *path;
@end
