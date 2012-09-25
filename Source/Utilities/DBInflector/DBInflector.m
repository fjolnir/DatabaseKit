#import "DBInflector.h"
#import "RegexKitLite.h"

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

    self.irregulars = @[
        #import "irregulars.inc"
    ];
    self.uncountables = @[
        #import "uncountables.inc"
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
    for(NSDictionary *inflection in self.uncountables) {
        if([inflection[@"pattern"] isEqualToString:[word lowercaseString]])
            return word;
    }
    for(NSDictionary *inflection in self.irregulars) {
        if([inflection[@"pattern"] isEqualToString:[word lowercaseString]])
            return inflection[@"replacement"];
    }
    NSString *transformed;
    for(NSDictionary *inflection in self.plurals) {
        transformed = [word stringByReplacingOccurrencesOfRegex:inflection[@"pattern"]
                                                     withString:inflection[@"replacement"]];
        if(![transformed isEqualToString:word])
            return transformed;
    }
    return word;
}
- (NSString *)singularizeWord:(NSString *)word
{
    for(NSDictionary *inflection in self.uncountables) {
        if([inflection[@"pattern"] isEqualToString:[word lowercaseString]])
            return word;
    }
    for(NSDictionary *inflection in self.irregulars) {
        if([inflection[@"replacement"] isEqualToString:[word lowercaseString]])
            return inflection[@"pattern"];
    }
    NSString *transformed;
    for(NSDictionary *inflection in self.singulars) {
        transformed = [word stringByReplacingOccurrencesOfRegex:inflection[@"pattern"]
                                                     withString:inflection[@"replacement"]];
        if(![transformed isEqualToString:word])
            return transformed;
    }
    return word;
}

@end
