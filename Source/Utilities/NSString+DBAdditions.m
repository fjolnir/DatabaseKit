#import "NSString+DBAdditions.h"
#import "DBInflector.h"

@implementation NSString (Inflections)
- (NSString *)db_pluralizedString
{
    NSArray *words = [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(words.count == 1)
        return [[DBInflector sharedInflector] pluralizeWord:words.firstObject];
    else {
        NSMutableString *ret = [NSMutableString string];
        for(NSString *word in words)
        {
            [ret appendString:[[DBInflector sharedInflector] pluralizeWord:word]];
        }
        return ret;
    }
}
- (NSString *)db_singularizedString
{
    NSArray *words = [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(words.count == 1)
        return [[DBInflector sharedInflector] singularizeWord:words.firstObject];
    else {
        NSMutableString *ret = [NSMutableString string];
        for(NSString *word in words)
        {
            [ret appendString:[[DBInflector sharedInflector] singularizeWord:word]];
        }
        return ret;
    }
}

- (NSString *)db_stringByCapitalizingFirstLetter
{
    NSString *capitalized = [self capitalizedString];
    return [self stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                         withString:[capitalized substringWithRange:NSMakeRange(0, 1)]];
}
- (NSString *)db_stringByDecapitalizingFirstLetter
{
    NSString *lowercase = [self lowercaseString];
    return [self stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                         withString:[lowercase substringWithRange:NSMakeRange(0, 1)]];
}

- (NSString *)sqlRepresentationForQuery:(DBQuery *)query
                         withParameters:(NSMutableArray *)parameters
{
    if([self isEqualToString:@"*"])
        return self;
    if([self hasSuffix:@".*"])
        return [NSString stringWithFormat:@"`%@`.*", [self substringToIndex:self.length-2]];
    else
        return [NSString stringWithFormat:@"`%@`", self];
}
@end
