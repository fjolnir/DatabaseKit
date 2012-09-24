#import "ARInflector.h"
#import "RegexKitLite.h"

static ARInflector *sharedInstance = nil;

@implementation ARInflector
@synthesize irregulars, uncountables, plurals, singulars;

+ (ARInflector *)sharedInflector
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

    // Open the list of inflections
#if TARGET_OS_MAC
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
#elif (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
    NSBundle *bundle = [NSBundle mainBundle];
#endif
    self.irregulars = [NSArray arrayWithContentsOfFile:[bundle pathForResource:@"irregulars"
                                                                        ofType:@"plist"]];
    self.uncountables = [NSArray arrayWithContentsOfFile:[bundle pathForResource:@"uncountables"
                                                                          ofType:@"plist"]];
    self.plurals = [NSArray arrayWithContentsOfFile:[bundle pathForResource:@"plurals"
                                                                     ofType:@"plist"]];
    self.singulars = [NSArray arrayWithContentsOfFile:[bundle pathForResource:@"singulars"
                                                                       ofType:@"plist"]];

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
