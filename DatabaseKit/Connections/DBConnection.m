#import "DBConnection.h"
#import <dispatch/dispatch.h>

#define NOT_IMPLEMENTED [NSException raise:@"Unimplemented" format:@"DBConnection can not be used directly!"]

static NSMutableArray *_ConnectionClasses;

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
- (NSDictionary *)columnsForTable:(NSString *)tableName
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

- (BOOL)transaction:(DBTransactionBlock)aBlock
{
    @try {
        if(![self beginTransaction])
            return NO;
        switch(aBlock()) {
            case DBTransactionRollBack:
                return [self rollBack];
            case DBTransactionCommit:
                return [self endTransaction];
        }
    }
    @catch(NSException *_) {
        [self rollBack];
        return NO;
    }
    return YES;
}

@end
