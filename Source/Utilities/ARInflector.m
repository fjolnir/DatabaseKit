//
//  ARInflector.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 9.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import "ARInflector.h"
#import "AGRegex.h"
static ARInflector *sharedInstance = nil;

@implementation ARInflector
@synthesize irregulars, uncountables, plurals, singulars;

+ (ARInflector *)sharedInflector
{
  if(!sharedInstance)
    sharedInstance = [[self alloc] init];
  
  return [[sharedInstance retain] autorelease];
}

- (id)init
{
  if(![super init])
    return nil;
  
  // Open the list of inflections
#if TARGET_OS_MAC
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
#elif TARGET_OS_IPHONE
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
  for(NSDictionary *inflection in self.uncountables)
  {
    if([[inflection objectForKey:@"pattern"] isEqualToString:[word lowercaseString]])
      return word;
  }
  for(NSDictionary *inflection in self.irregulars)
  {
    if([[inflection objectForKey:@"pattern"] isEqualToString:[word lowercaseString]])
      return [inflection objectForKey:@"replacement"];
  }
  AGRegex *regularExpression;
  for(NSDictionary *inflection in self.plurals)
  {
    regularExpression = [AGRegex regexWithPattern:[inflection objectForKey:@"pattern"]
                                          options:AGRegexCaseInsensitive];
    if([regularExpression findInString:word])
    {
      return [regularExpression replaceWithString:[inflection objectForKey:@"replacement"]
                                         inString:word];
    }
  }
  return word;
}
- (NSString *)singularizeWord:(NSString *)word
{
  for(NSDictionary *inflection in self.uncountables)
  {
    if([[inflection objectForKey:@"pattern"] isEqualToString:[word lowercaseString]])
      return word;
  }
  for(NSDictionary *inflection in self.irregulars)
  {
    if([[inflection objectForKey:@"replacement"] isEqualToString:[word lowercaseString]])
      return [inflection objectForKey:@"pattern"];
  }
  AGRegex *regularExpression;
  for(NSDictionary *inflection in self.singulars)
  {
    regularExpression = [AGRegex regexWithPattern:[inflection objectForKey:@"pattern"]
                                          options:AGRegexCaseInsensitive];
    if([regularExpression findInString:word])
    {
      return [regularExpression replaceWithString:[inflection objectForKey:@"replacement"]
                                         inString:word];
    }
  }
  return word;
}

- (void)dealloc
{
  [self.irregulars release];
  [self.uncountables release];
  [self.plurals release];
  [self.singulars release];
  
  [super dealloc];
}
@end
