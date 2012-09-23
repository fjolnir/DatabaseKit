#import "ARQuery.h"

@implementation ARQuery
@synthesize queryString=_queryString, parameters=_parameters, limit=_limit, order=_order;

+ (ARQuery *)queryWithString:(NSString *)queryString
                  parameters:(NSDictionary *)parameters
                       limit:(NSUInteger)limit
                       order:(AROrder)order
{
    return [[[self alloc] initWithString:queryString parameters:parameters limit:limit order:order] autorelease];
}

- (id)initWithString:(NSString *)queryString
          parameters:(NSDictionary *)parameters
               limit:(NSUInteger)limit
               order:(AROrder)order
{
    if(!(self = [super init]))
        return nil;
    self.queryString = queryString;
    self.parameters  = parameters;
    self.limit       = limit;
    self.order       = order;
    return self;
}

- (NSString *)preparedQueryString
{
    NSMutableString *prepped = [_queryString mutableCopy];

    switch(_order) {
        case AROrderAscending:
            [prepped appendFormat:@" ORDER ASC"];
            break;
        case AROrderDescending:
            [prepped appendFormat:@" ORDER DESC"];
            break;
        default:
            NSAssert(NO, @"Invalid order");
    }
    if(_limit > 0)
        [prepped appendFormat:@" LIMIT %ld", _limit];
    return prepped;
}
@end
