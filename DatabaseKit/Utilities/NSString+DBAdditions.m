#import "NSString+DBAdditions.h"
#import "DBInflector/DBInflector.h"

@implementation NSString (Inflections)
- (NSString *)db_pluralizedString
{
  NSArray *words = [self componentsSeparatedByString:@" "];
  NSMutableString *ret = [NSMutableString string];
  for(NSString *word in words)
  {
    [ret appendString:[[DBInflector sharedInflector] pluralizeWord:word]];
  }
  
  return ret;
}
- (NSString *)db_singularizedString
{
  NSArray *words = [self componentsSeparatedByString:@" "];
  NSMutableString *ret = [NSMutableString string];
  for(NSString *word in words)
  {
    [ret appendString:[[DBInflector sharedInflector] singularizeWord:word]];
  }
  
  return ret;
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

- (NSString *)db_underscoredString
{
    NSString *underscored = [self stringByReplacingOccurrencesOfString:@"([A-Z]+)([A-Z][a-z])"
                                                            withString:@"$1_$2"
                                                               options:NSRegularExpressionSearch
                                                                 range:(NSRange) { 0, [self length] }];
    underscored = [underscored stringByReplacingOccurrencesOfString:@"([a-z\\d])([A-Z])"
                                                         withString:@"$1_$2"
                                                            options:NSRegularExpressionSearch
                                                              range:(NSRange) { 0, [underscored length] }];
    
    return [underscored lowercaseString];
}
- (NSString *)db_camelizedString
{
    NSMutableArray *parts = [[self componentsSeparatedByString:@"_"] mutableCopy];
    NSMutableString *ret = [NSMutableString stringWithString:parts[0]];
    [parts removeObjectAtIndex:0];
    for(NSString *part in parts)
    {
        [ret appendString:[part db_stringByCapitalizingFirstLetter]];
    }
    return ret;
}

- (NSString *)toString
{
    return self;
}
@end
