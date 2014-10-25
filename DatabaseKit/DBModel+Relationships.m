#import "DBModel+Relationships.h"
#import "NSString+DBAdditions.h"

@implementation DBModel (Relationships)
+ (Class)relatedClassForKey:(NSString *)key
{
    Class klass;
    if([self typeForKey:key class:&klass] == '@') {
        if([klass isSubclassOfClass:[NSSet class]])
            return NSClassFromString([@"TE" stringByAppendingString:[[key singularizedString] stringByCapitalizingFirstLetter]]);
    }
    return nil;
}
+ (NSString *)foreignKeyName
{
    return [[[self tableName] singularizedString] stringByAppendingString:@"Identifier"];
}
@end
