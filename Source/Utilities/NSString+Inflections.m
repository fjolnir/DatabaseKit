//
//  NSString+Inflections.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 9.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import "NSString+Inflections.h"
#import "ARInflector.h"
#import "AGRegex.h"

/* @cond IGNORE */
@implementation NSString (Inflections)
- (NSString *)pluralizedString
{
  NSArray *words = [self componentsSeparatedByString:@" "];
  NSMutableString *ret = [NSMutableString string];
  for(NSString *word in words)
  {
    [ret appendString:[[ARInflector sharedInflector] pluralizeWord:word]];
  }
  
  return ret;
}
- (NSString *)singularizedString
{
  NSArray *words = [self componentsSeparatedByString:@" "];
  NSMutableString *ret = [NSMutableString string];
  for(NSString *word in words)
  {
    [ret appendString:[[ARInflector sharedInflector] singularizeWord:word]];
  }
  
  return ret;
}

- (NSString *)stringByCapitalizingFirstLetter
{
	NSString *capitalized = [self capitalizedString];
	if([self length] > 1)
		return [NSString stringWithFormat:@"%@%@", [capitalized substringWithRange:NSMakeRange(0, 1)], [self substringWithRange:NSMakeRange(1, [self length] - 1)]];
	return capitalized;
}
- (NSString *)stringByDecapitalizingFirstLetter
{
	NSString *lowercase = [self lowercaseString];
	if([self length] > 1)
		return [NSString stringWithFormat:@"%@%@", [lowercase substringWithRange:NSMakeRange(0, 1)], [self substringWithRange:NSMakeRange(1, [self length] - 1)]];
	return lowercase;
}

- (NSString *)underscoredString
{
	AGRegex *regex = [AGRegex regexWithPattern:@"([A-Z]+)([A-Z][a-z])" options:AGRegexExtended];
	NSString *ret = [regex replaceWithString:@"$1_$2" inString:self];
	regex = [AGRegex regexWithPattern:@"([a-z\\d])([A-Z])"];
	ret = [regex replaceWithString:@"$1_$2" inString:ret];
	
	return [ret lowercaseString];
}
- (NSString *)camelizedString
{
	NSMutableArray *parts = [[self componentsSeparatedByString:@"_"] mutableCopy];
	NSMutableString *ret = [NSMutableString stringWithString:[parts objectAtIndex:0]];
	[parts removeObjectAtIndex:0];
	for(NSString *part in parts)
	{
		[ret appendString:[part stringByCapitalizingFirstLetter]];
	}
	[parts release];
	return ret;
}
@end
/* @endcond */