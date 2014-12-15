#import "DBInflector.h"
#import <dispatch/dispatch.h>

static DBInflector *sharedInstance = nil;

@implementation DBInflector
@synthesize irregulars, uncountables, plurals, singulars;

+ (DBInflector *)sharedInflector
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (id)init
{
    if(!(self = [super init]))
        return nil;

    singularCache = [NSCache new];
    pluralCache   = [NSCache new];

    self.irregulars = @[
        #import "irregulars.inc"
    ];
    self.uncountables = [NSSet setWithObjects:
        #import "uncountables.inc"
        , nil
    ];
    self.plurals = @[
        #import "plurals.inc"
    ];
    self.singulars = @[
        #import "singulars.inc"
    ];

    return self;
}
- (NSString *)pluralizeWord:(NSString *)word
{
    NSString *pluralized = [pluralCache objectForKey:word];
    if(pluralized)
        return pluralized;

    if([self.uncountables containsObject:[word lowercaseString]]) {
        pluralized = word;
        goto done;
    }
    
    for(NSDictionary *inflection in self.irregulars) {
        if([inflection[@"pattern"] isEqualToString:[word lowercaseString]]) {
            pluralized = inflection[@"replacement"];
            goto done;
        }
    }

    for(NSDictionary *inflection in self.plurals) {
        NSString *transformed = [word stringByReplacingOccurrencesOfString:inflection[@"pattern"]
                                                                withString:inflection[@"replacement"]
                                                                   options:NSRegularExpressionSearch|NSRegularExpressionCaseInsensitive
                                                                     range:(NSRange) { 0, [word length] }];
        if(![transformed isEqualToString:word]) {
            pluralized = transformed;
            goto done;
        }
    }
    
done:
    if(!pluralized) pluralized = word;
    [pluralCache setObject:pluralized forKey:word];
    return pluralized;
}
- (NSString *)singularizeWord:(NSString *)word
{
    NSString *singularized = [singularCache objectForKey:word];
    if(singularized)
        return singularized;
    
    for(NSString *pattern in self.uncountables) {
        if([pattern isEqualToString:[word lowercaseString]]) {
            singularized = word;
            goto done;
        }
    }
    for(NSDictionary *inflection in self.irregulars) {
        if([inflection[@"replacement"] isEqualToString:[word lowercaseString]]) {
            singularized = inflection[@"pattern"];
            goto done;
        }
    }
    for(NSDictionary *inflection in self.singulars) {
        NSString *transformed = [word stringByReplacingOccurrencesOfString:inflection[@"pattern"]
                                                                withString:inflection[@"replacement"]
                                                                   options:NSRegularExpressionSearch|NSRegularExpressionCaseInsensitive
                                                                     range:(NSRange) { 0, [word length] }];
        if(![transformed isEqualToString:word]) {
            singularized = transformed;
            goto done;
        }
    }

done:
    if(!singularized) singularized = word;
    [singularCache setObject:singularized forKey:word];
    return singularized;
}

@end
