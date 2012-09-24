//
//  DBInflectorTest.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 9.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import "DBInflectorTest.h"
#import <DatabaseKit/DBInflector.h>
#import <DatabaseKit/NSString+DBAdditions.h>

@implementation DBInflectorTest
- (void)setUp
{
  inflector = [DBInflector sharedInflector];
}

- (void)testPluralization
{
  GHAssertTrue([[inflector pluralizeWord:@"guy"] isEqualToString:@"guys"], @"guy should become guys");
  GHAssertTrue([[inflector pluralizeWord:@"octopus"] isEqualToString:@"octopi"], @"octopus should become octopi");
  GHAssertTrue([[inflector pluralizeWord:@"person"] isEqualToString:@"people"], @"person should become people");
  GHAssertTrue([[inflector pluralizeWord:@"mother"] isEqualToString:@"mothers"], @"mother should become mothers");
  GHAssertTrue([[inflector pluralizeWord:@"equipment"] isEqualToString:@"equipment"], @"equipment should become equipment");
}

- (void)testSingularization
{
  GHAssertTrue([[inflector singularizeWord:@"guys"] isEqualToString:@"guy"], @"guys should become guy");
  GHAssertTrue([[inflector singularizeWord:@"octopi"] isEqualToString:@"octopus"], @"octopi should become octopus");
  GHAssertTrue([[inflector singularizeWord:@"people"] isEqualToString:@"person"], @"people should become person");
  GHAssertTrue([[inflector singularizeWord:@"mothers"] isEqualToString:@"mother"], @"mothers should become mother");
  GHAssertTrue([[inflector singularizeWord:@"equipment"] isEqualToString:@"equipment"], @"equipment should become equipment");
}

- (void)testPluralizationWithStringCategory
{
  GHAssertTrue([[@"guy" pluralizedString] isEqualToString:@"guys"], @"guy should become guys");
  GHAssertTrue([[@"octopus" pluralizedString] isEqualToString:@"octopi"], @"octopus should become octopi");
  GHAssertTrue([[@"person" pluralizedString] isEqualToString:@"people"], @"person should become people");
  GHAssertTrue([[@"mother" pluralizedString] isEqualToString:@"mothers"], @"mother should become mothers");
  GHAssertTrue([[@"equipment" pluralizedString] isEqualToString:@"equipment"], @"equipment should become equipment");
}

- (void)testSingularizationWithStringCategory
{
  GHAssertTrue([[@"guys" singularizedString] isEqualToString:@"guy"], @"guys should become guy");
  GHAssertTrue([[@"octopi" singularizedString] isEqualToString:@"octopus"], @"octopi should become octopus");
  GHAssertTrue([[@"people" singularizedString] isEqualToString:@"person"], @"people should become person");
  GHAssertTrue([[@"mothers" singularizedString] isEqualToString:@"mother"], @"mothers should become mother");
  GHAssertTrue([[@"equipment" singularizedString] isEqualToString:@"equipment"], @"equipment should become equipment");
}

- (void)testUnderscoring
{
	GHAssertEqualObjects([@"MyCamelizedString" underscoredString], @"my_camelized_string", @"underscore test failed");
}

- (void)testCamelizing
{
	GHAssertEqualObjects([@"my_underscored_string" camelizedString], @"myUnderscoredString", @"camelize test failed");
}
@end
