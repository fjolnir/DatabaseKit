#import "DB.h"
#import "DBTable.h"

@interface DB ()
@property(readwrite, strong) DBConnection *connection;
@end

@implementation DB

+ (DB *)withURL:(NSURL *)URL
{
    DB *ret = [self new];
    NSError *err = nil;
    ret.connection = [DBConnectionPool openConnectionWithURL:URL error:&err];
    if(err)
        return nil;
    return ret;
}

// Returns a table whose name matches key
- (id)objectForKeyedSubscript:(id)key
{
    NSParameterAssert([key isKindOfClass:[NSString class]]);
    return [DBTable withConnection:_connection name:key];
}

@end
