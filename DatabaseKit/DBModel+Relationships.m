#import "DBModel+Relationships.h"
#import "NSString+DBAdditions.h"
#import <objc/runtime.h>

@implementation DBModel (Relationships)
+ (Class)relatedClassForKey:(NSString *)key
{
    Class klass;
    if([self typeForKey:key class:&klass] == _C_ID) {
        if([klass isSubclassOfClass:[NSSet class]])
            return NSClassFromString([[self classPrefix] stringByAppendingString:[[key singularizedString] stringByCapitalizingFirstLetter]]);
        else if([klass isSubclassOfClass:[DBModel class]])
            return NSClassFromString([[self classPrefix] stringByAppendingString:[key stringByCapitalizingFirstLetter]]);
    }
    return nil;
}

+ (NSString *)foreignKeyName
{
    return [[[self tableName] singularizedString] stringByAppendingString:@"Identifier"];
}
@end
