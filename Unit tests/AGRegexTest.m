//
//  AGRegexTest.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 9.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import "AGRegexTest.h"
#import "AGRegex.h"

@implementation AGRegexTest
- (void)testFind
{
  AGRegex *regex = [AGRegex regexWithPattern:@"^\\/(([a-z]|\\^|\\$|\\(|\\)|\\[|\\]|\\|)+)\\/"
                                     options:AGRegexCaseInsensitive];
  AGRegexMatch *match = [regex findInString:@"/(hive)$/i, '$1s'"];
  STAssertNotNil(match, @"Find should have succeeded");
}
- (void)testReplace
{
  AGRegex *regex = [AGRegex regexWithPattern:@"^\\/(([a-z]|\\^|\\$|\\(|\\)|\\[|\\]|\\|)+)\\/"
                                     options:AGRegexCaseInsensitive];
  NSString *final = [regex replaceWithString:@"foo $2" inString:@"/(hive)$/i, '$1s'"];
  NSString *expected = @"foo $i, '$1s'";
  STAssertTrue([final isEqualToString:expected], @"After replacement, result should be: %@", expected); 
  
  regex = [AGRegex regexWithPattern:@"([a-z]+)$"
                            options:AGRegexCaseInsensitive];
  final = [regex replaceWithString:@"$1s" inString:@"guy"];
  expected = @"guys";
  STAssertTrue([final isEqualToString:expected], @"After replacement, result should be: %@ but was: %@", expected, final); 

}
@end
