#import "DB.h"
#import "DBTable.h"

@interface DB ()
@property(readwrite, strong) DBConnection *connection;
@end

@implementation DB

+ (DB *)withURL:(NSURL *)URL
{
    return [self withURL:URL error:NULL];
}

+ (DB *)withURL:(NSURL *)URL error:(NSError **)err
{
    return [[self alloc] initWithConnection:[DBConnectionPool openConnectionWithURL:URL error:err]];
}

- (id)initWithConnection:(DBConnection *)aConnection
{
    if((self = [super init]))
        _connection = aConnection;
    return self && _connection ? self : nil;
}

// Returns a table whose name matches key
- (id)objectForKeyedSubscript:(id)key
{
    NSParameterAssert([key isKindOfClass:[NSString class]]);
    return [DBTable withDatabase:self name:key];
}

@end
