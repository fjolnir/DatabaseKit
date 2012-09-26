#import "DBConnection.h"

#define NOT_IMPLEMENTED [NSException raise:@"Unimplemented" format:@"DBConnection can not be used directly!"]

static NSMutableArray *_ConnectionClasses;
id DBConnectionRollback = @"DBConnectionRollback";

@interface DBConnection ()
@property(readwrite, retain) NSURL *URL;
@end

@implementation DBConnection
+ (BOOL)canHandleURL:(NSURL *)URL
{
    return NO;
}
+ (void)registerConnectionClass:(Class)kls
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _ConnectionClasses = [NSMutableArray array];
    });
    [_ConnectionClasses addObject:kls];
}
+ (id)openConnectionWithURL:(NSURL *)URL error:(NSError **)err
{
    if([URL isKindOfClass:[NSString class]])
        URL = [NSURL URLWithString:(NSString *)URL];
    for(Class kls in _ConnectionClasses) {
        if([kls canHandleURL:URL])
            return [[kls alloc] initWithURL:URL error:err];
    }
    if(err)
        *err = [NSError errorWithDomain:DBConnectionErrorDomain
                                   code:0
                               userInfo:@{ NSLocalizedDescriptionKey: @"Unhandled URL type", @"url": URL }];
    return nil;
}
- (id)initWithURL:(NSURL *)URL error:(NSError **)err
{
    if(!(self = [super init]))
        return nil;
    self.URL = URL;
    return self;
}
- (NSArray *)executeSQL:(NSString *)sql substitutions:(id)substitutions error:(NSError **)outErr
{
    NOT_IMPLEMENTED;
    return nil;
}
- (BOOL)closeConnection
{
    NOT_IMPLEMENTED;
    return NO;
}
- (NSArray *)columnsForTable:(NSString *)tableName
{
    NOT_IMPLEMENTED;
    return nil;
}
- (BOOL)beginTransaction
{
    NOT_IMPLEMENTED;
    return NO;
}
- (BOOL)rollBack
{
    NOT_IMPLEMENTED;
    return NO;
}
- (BOOL)endTransaction
{
    NOT_IMPLEMENTED;
    return NO;
}

- (id)transaction:(DBConnectionBlock)block
{
    [self beginTransaction];
    id ret;
    @try {
        ret = block();
        if(ret == DBConnectionRollback) {
            ret = nil;
            [self rollBack];
        } else
            [self endTransaction];
    } @catch(NSException *e) {
        [self rollBack];
        [e raise];
        return nil;
    }
    return ret;
}
@end
