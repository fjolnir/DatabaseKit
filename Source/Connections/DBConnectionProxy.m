#import "DBConnectionProxy.h"
#import "DBConnection.h"
#import "Debug.h"
#import <pthread.h>

@implementation DBConnectionProxy
@dynamic connection;

+ (instancetype)connectionProxyWithURL:(NSURL *)URL error:(NSError **)err
{
    DBConnectionProxy *proxy = [self alloc];
    if(proxy) {
        proxy->_connectionURL = URL;
        if(!proxy.connection)
            return nil;
    }
    return proxy;
}

- (DBConnection *)connection
{
    return [self connection:NULL];
}

- (DBConnection *)connection:(NSError **)outErr
{
    [NSException raise:NSInternalInconsistencyException
                format:@"Abstract method %@ not implemented for %@",
                       NSStringFromSelector(_cmd), [self class]];
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
