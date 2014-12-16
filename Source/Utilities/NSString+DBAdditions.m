#import "NSString+DBAdditions.h"
#import "DBInflector.h"

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

- (NSString *)sqlRepresentationForQuery:(DBQuery *)query
                         withParameters:(NSMutableArray *)parameters
{
    return self;
}
@end
