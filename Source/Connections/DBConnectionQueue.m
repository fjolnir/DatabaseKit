#import "DBConnectionQueue.h"
#import "DBConnection.h"
#import "Debug.h"
#import <pthread.h>

@interface DBConnectionQueue () {
    DBConnection *_connection;
    dispatch_queue_t _queue;
}
@end

static const char *kDBExecutingQueueKey = (void *)&kDBExecutingQueueKey;

@implementation DBConnectionQueue

+ (id)connectionProxyWithURL:(NSURL *)URL error:(NSError **)err
{
    DBConnectionQueue *queueProxy = [super connectionProxyWithURL:URL error:err];
    if(queueProxy) {
        NSString *queueName = [NSString stringWithFormat:@"DBQueue: %@", URL.absoluteString];
        queueProxy->_connection = [DBConnection openConnectionWithURL:URL error:err];
        queueProxy->_queue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(queueProxy->_queue, kDBExecutingQueueKey, queueProxy->_queue, NULL);
    }
    return queueProxy;
}

- (DBConnection *)connection:(NSError **)err
{
    return _connection;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    invocation.target = self.connection;
    if(dispatch_get_specific(kDBExecutingQueueKey) == _queue)
        [super forwardInvocation:invocation];
    else
        dispatch_sync(_queue, ^{
            [super forwardInvocation:invocation];
        });
}

@end
