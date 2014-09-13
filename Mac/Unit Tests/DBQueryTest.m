//
//  DBQueryTest.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 9/6/13.
//
//

#import <XCTest/XCTest.h>
#import <DatabaseKit/DatabaseKit.h>

@interface DBQueryTest : XCTestCase

@end

#define Q [DBQuery withTable:[DBTable withDatabase:nil name:@"aTable"]]

@implementation DBQueryTest

- (void)testBuilding
{
    XCTAssertEqualObjects([[[[Q select] where:@{ @"foo": @1 }] order:DBOrderDescending by:@[@"index"]] toString],
                          @"SELECT * FROM aTable WHERE \"foo\"=$1 ORDER BY \"index\" DESC", @"");
    
    NSArray *fields = @[@"a", @"b", @"c"];
    XCTAssertEqualObjects([[Q select:fields] toString],
                          @"SELECT \"a\", \"b\", \"c\" FROM aTable", @"");
    
    NSDictionary *update = @{ @"a": @1, @"b": @2, @"c": @3 };
    XCTAssertEqualObjects([[Q update:update] toString],
                          @"UPDATE aTable SET \"a\"=$1, \"b\"=$2, \"c\"=$3", @"");
    
    XCTAssertEqualObjects([[Q delete] toString], @"DELETE FROM aTable", @"");
}

@end
