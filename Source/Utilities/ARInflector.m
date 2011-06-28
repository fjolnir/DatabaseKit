//
//  ARInflector.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 9.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import "ARInflector.h"
#import "RegexKitLite.h"

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
  if(!(self = [super init]))
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
  NSString *transformed;
  for(NSDictionary *inflection in self.plurals)
  {
    transformed = [word stringByReplacingOccurrencesOfRegex:[inflection objectForKey:@"pattern"]
                                                 withString:[inflection objectForKey:@"replacement"]];
    if(![transformed isEqualToString:word])
      return transformed;
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
  NSString *transformed;
  for(NSDictionary *inflection in self.singulars)
  {
    transformed = [word stringByReplacingOccurrencesOfRegex:[inflection objectForKey:@"pattern"]
                                                 withString:[inflection objectForKey:@"replacement"]];
    if(![transformed isEqualToString:word])
      return transformed;
  }
  return word;
}

- (void)dealloc
{
  [irregulars release];
  [uncountables release];
  [plurals release];
  [singulars release];
  
  [super dealloc];
}
@end
