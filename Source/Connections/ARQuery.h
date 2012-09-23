#import <Foundation/Foundation.h>

typedef enum {
    AROrderDescending = 0,
    AROrderAscending
} AROrder;

@interface ARQuery : NSObject
@property(readwrite, copy) NSString *queryString;
@property(readwrite, copy) NSDictionary *parameters;
@property(readwrite, assign) NSUInteger limit;
@property(readwrite, assign) AROrder order;

+ (ARQuery *)queryWithString:(NSString *)queryString
                  parameters:(NSDictionary *)parameters
                       limit:(NSUInteger)limit
                       order:(AROrder)order;

- (id)initWithString:(NSString *)queryString
          parameters:(NSDictionary *)parameters
               limit:(NSUInteger)limit
               order:(AROrder)order;

- (NSString *)preparedQueryString;
@end
