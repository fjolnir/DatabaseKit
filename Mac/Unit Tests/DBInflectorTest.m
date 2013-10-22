//
//  DBInflectorTest.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 9.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <DatabaseKit/Utilities/DBInflector/DBInflector.h>
#import <DatabaseKit/Utilities/NSString+DBAdditions.h>

@class DBInflector;

@interface DBInflectorTest : XCTestCase {
    DBInflector *inflector;
}

@end


@implementation DBInflectorTest
- (void)setUp
{
  inflector = [DBInflector sharedInflector];
}

- (void)testPluralization
{
  XCTAssertTrue([[inflector pluralizeWord:@"guy"] isEqualToString:@"guys"], @"guy should become guys");
  XCTAssertTrue([[inflector pluralizeWord:@"octopus"] isEqualToString:@"octopi"], @"octopus should become octopi");
  XCTAssertTrue([[inflector pluralizeWord:@"person"] isEqualToString:@"people"], @"person should become people");
  XCTAssertTrue([[inflector pluralizeWord:@"mother"] isEqualToString:@"mothers"], @"mother should become mothers");
  XCTAssertTrue([[inflector pluralizeWord:@"equipment"] isEqualToString:@"equipment"], @"equipment should become equipment");
}

- (void)testSingularization
{
  XCTAssertTrue([[inflector singularizeWord:@"guys"] isEqualToString:@"guy"], @"guys should become guy");
  XCTAssertTrue([[inflector singularizeWord:@"octopi"] isEqualToString:@"octopus"], @"octopi should become octopus");
  XCTAssertTrue([[inflector singularizeWord:@"people"] isEqualToString:@"person"], @"people should become person");
  XCTAssertTrue([[inflector singularizeWord:@"mothers"] isEqualToString:@"mother"], @"mothers should become mother");
  XCTAssertTrue([[inflector singularizeWord:@"equipment"] isEqualToString:@"equipment"], @"equipment should become equipment");
}

- (void)testPluralizationWithStringCategory
{
  XCTAssertTrue([[@"guy" pluralizedString] isEqualToString:@"guys"], @"guy should become guys");
  XCTAssertTrue([[@"octopus" pluralizedString] isEqualToString:@"octopi"], @"octopus should become octopi");
  XCTAssertTrue([[@"person" pluralizedString] isEqualToString:@"people"], @"person should become people");
  XCTAssertTrue([[@"mother" pluralizedString] isEqualToString:@"mothers"], @"mother should become mothers");
  XCTAssertTrue([[@"equipment" pluralizedString] isEqualToString:@"equipment"], @"equipment should become equipment");
}

- (void)testSingularizationWithStringCategory
{
  XCTAssertTrue([[@"guys" singularizedString] isEqualToString:@"guy"], @"guys should become guy");
  XCTAssertTrue([[@"octopi" singularizedString] isEqualToString:@"octopus"], @"octopi should become octopus");
  XCTAssertTrue([[@"people" singularizedString] isEqualToString:@"person"], @"people should become person");
  XCTAssertTrue([[@"mothers" singularizedString] isEqualToString:@"mother"], @"mothers should become mother");
  XCTAssertTrue([[@"equipment" singularizedString] isEqualToString:@"equipment"], @"equipment should become equipment");
}

- (void)testUnderscoring
{
    XCTAssertEqualObjects([@"MyCamelizedString" underscoredString], @"my_camelized_string", @"underscore test failed");
}

- (void)testCamelizing
{
    XCTAssertEqualObjects([@"my_underscored_string" camelizedString], @"myUnderscoredString", @"camelize test failed");
}
@end
