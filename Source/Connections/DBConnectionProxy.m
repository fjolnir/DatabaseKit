#import "DBConnectionProxy.h"
#import "DBConnection.h"
#import "DBDebug.h"
#import "DBUtilities.h"

@implementation DBConnectionProxy
@dynamic connection;

+ (instancetype)connectionProxyWithURL:(NSURL *)URL error:(NSError **)err
{
    DBConnectionProxy *proxy = [self alloc];
    if(proxy)
        proxy->_connectionURL = URL;
    return proxy;
}

- (DBConnection *)connection
{
    return [self connection:NULL];
}

- (DBConnection *)connection:(NSError **)outErr
{
    DBNotImplemented();
    return nil;
}

- (Class)class
{
    return self.connection.class;
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return [self.connection methodSignatureForSelector:sel];
}
- (void)forwardInvocation:(NSInvocation *)invocation
{
    invocation.target = self.connection;
    [invocation invoke];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p (%@)>", [self class], self, _connectionURL];
}
@end
