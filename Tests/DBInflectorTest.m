#import <XCTest/XCTest.h>
#import "../Source/Utilities/DBInflector/DBInflector.h"
#import "../Source/Utilities/NSString+DBAdditions.h"

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
  XCTAssertTrue([[@"guy" db_pluralizedString] isEqualToString:@"guys"], @"guy should become guys");
  XCTAssertTrue([[@"octopus" db_pluralizedString] isEqualToString:@"octopi"], @"octopus should become octopi");
  XCTAssertTrue([[@"person" db_pluralizedString] isEqualToString:@"people"], @"person should become people");
  XCTAssertTrue([[@"mother" db_pluralizedString] isEqualToString:@"mothers"], @"mother should become mothers");
  XCTAssertTrue([[@"equipment" db_pluralizedString] isEqualToString:@"equipment"], @"equipment should become equipment");
}

- (void)testSingularizationWithStringCategory
{
  XCTAssertTrue([[@"guys" db_singularizedString] isEqualToString:@"guy"], @"guys should become guy");
  XCTAssertTrue([[@"octopi" db_singularizedString] isEqualToString:@"octopus"], @"octopi should become octopus");
  XCTAssertTrue([[@"people" db_singularizedString] isEqualToString:@"person"], @"people should become person");
  XCTAssertTrue([[@"mothers" db_singularizedString] isEqualToString:@"mother"], @"mothers should become mother");
  XCTAssertTrue([[@"equipment" db_singularizedString] isEqualToString:@"equipment"], @"equipment should become equipment");
}

- (void)testUnderscoring
{
    XCTAssertEqualObjects([@"MyCamelizedString" db_underscoredString], @"my_camelized_string", @"underscore test failed");
}

- (void)testCamelizing
{
    XCTAssertEqualObjects([@"my_underscored_string" db_camelizedString], @"myUnderscoredString", @"camelize test failed");
}
@end
