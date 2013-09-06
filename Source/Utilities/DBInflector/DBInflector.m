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

    singularCache = [NSCache new];
    pluralCache   = [NSCache new];

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
    NSString *pluralized = [pluralCache objectForKey:word];
    if(pluralized)
        return pluralized;
    
    for(NSDictionary *inflection in self.uncountables) {
        if([inflection[@"pattern"] isEqualToString:[word lowercaseString]]) {
            pluralized = word;
            break;
        }
    }
    for(NSDictionary *inflection in self.irregulars) {
        if([inflection[@"pattern"] isEqualToString:[word lowercaseString]]) {
            pluralized = inflection[@"pattern"];
            break;
        }
    }
    NSString *transformed;
    for(NSDictionary *inflection in self.plurals) {
        transformed = [word stringByReplacingOccurrencesOfRegex:inflection[@"pattern"]
                                                     withString:inflection[@"replacement"]];
        if(![transformed isEqualToString:word]) {
            pluralized = transformed;
            break;
        }
    }
    if(!pluralized) pluralized = word;
    [pluralCache setObject:pluralized forKey:word];
    return pluralized;
}
- (NSString *)singularizeWord:(NSString *)word
{
    NSString *singularized = [singularCache objectForKey:word];
    if(singularized)
        return singularized;
    
    for(NSDictionary *inflection in self.uncountables) {
        if([inflection[@"pattern"] isEqualToString:[word lowercaseString]]) {
            singularized = word;
            break;
        }
    }
    for(NSDictionary *inflection in self.irregulars) {
        if([inflection[@"replacement"] isEqualToString:[word lowercaseString]]) {
            singularized = inflection[@"pattern"];
            break;
        }
    }
    NSString *transformed;
    for(NSDictionary *inflection in self.singulars) {
        transformed = [word stringByReplacingOccurrencesOfRegex:inflection[@"pattern"]
                                                     withString:inflection[@"replacement"]];
        if(![transformed isEqualToString:word]) {
            singularized = transformed;
            break;
        }
    }
    if(!singularized) singularized = word;
    [singularCache setObject:singularized forKey:word];
    return singularized;
}

@end
