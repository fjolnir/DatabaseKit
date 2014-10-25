#import <Foundation/Foundation.h>
#import <DatabaseKit/DBConnection.h>

typedef enum  {
    DBPostgreDatabaseNotFoundErrorCode = 0,
    DBPostgresConnectionFailed  = 1,
    DBPostgreQueryFailed = 2
} DBPostgreErrorCode;

@interface DBPostgresConnection : DBConnection

@end
