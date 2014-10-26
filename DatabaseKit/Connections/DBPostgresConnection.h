#import <Foundation/Foundation.h>
#import <DatabaseKit/DBConnection.h>

typedef NS_ENUM(NSUInteger, DBPostgresErrorCode)  {
    DBPostgresDatabaseNotFoundErrorCode = 0,
    DBPostgresConnectionFailed  = 1,
    DBPostgresQueryFailed = 2
};

@interface DBPostgresConnection : DBConnection
@end
