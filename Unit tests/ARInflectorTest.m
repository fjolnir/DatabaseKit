//
//  ARInflectorTest.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 9.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import "ARInflectorTest.h"
#import <ActiveRecord/ARInflector.h>
#import <ActiveRecord/NSString+Inflections.h>

@implementation ARInflectorTest
- (void)setUp
{
  inflector = [ARInflector sharedInflector];
}
- (void)testPluralization
{
  STAssertTrue([[inflector pluralizeWord:@"guy"] isEqualToString:@"guys"], @"guy should become guys");
  STAssertTrue([[inflector pluralizeWord:@"octopus"] isEqualToString:@"octopi"], @"octopus should become octopi");
  STAssertTrue([[inflector pluralizeWord:@"person"] isEqualToString:@"people"], @"person should become people");
  STAssertTrue([[inflector pluralizeWord:@"mother"] isEqualToString:@"mothers"], @"mother should become mothers");
  STAssertTrue([[inflector pluralizeWord:@"equipment"] isEqualToString:@"equipment"], @"equipment should become equipment");
}
- (void)testSingularization
{
  STAssertTrue([[inflector singularizeWord:@"guys"] isEqualToString:@"guy"], @"guys should become guy");
  STAssertTrue([[inflector singularizeWord:@"octopi"] isEqualToString:@"octopus"], @"octopi should become octopus");
  STAssertTrue([[inflector singularizeWord:@"people"] isEqualToString:@"person"], @"people should become person");
  STAssertTrue([[inflector singularizeWord:@"mothers"] isEqualToString:@"mother"], @"mothers should become mother");
  STAssertTrue([[inflector singularizeWord:@"equipment"] isEqualToString:@"equipment"], @"equipment should become equipment");
}

- (void)testPluralizationWithStringCategory
{
  STAssertTrue([[@"guy" pluralizedString] isEqualToString:@"guys"], @"guy should become guys");
  STAssertTrue([[@"octopus" pluralizedString] isEqualToString:@"octopi"], @"octopus should become octopi");
  STAssertTrue([[@"person" pluralizedString] isEqualToString:@"people"], @"person should become people");
  STAssertTrue([[@"mother" pluralizedString] isEqualToString:@"mothers"], @"mother should become mothers");
  STAssertTrue([[@"equipment" pluralizedString] isEqualToString:@"equipment"], @"equipment should become equipment");
}
- (void)testSingularizationWithStringCategory
{
  STAssertTrue([[@"guys" singularizedString] isEqualToString:@"guy"], @"guys should become guy");
  STAssertTrue([[@"octopi" singularizedString] isEqualToString:@"octopus"], @"octopi should become octopus");
  STAssertTrue([[@"people" singularizedString] isEqualToString:@"person"], @"people should become person");
  STAssertTrue([[@"mothers" singularizedString] isEqualToString:@"mother"], @"mothers should become mother");
  STAssertTrue([[@"equipment" singularizedString] isEqualToString:@"equipment"], @"equipment should become equipment");
}
@end
