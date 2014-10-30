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

#define Q(type) [DB##type##Query withTable:[DBTable withDatabase:[DB new] name:@"aTable"]]

@implementation DBQueryTest

- (void)testBuilding
{
    XCTAssertEqualObjects([[[[Q(Select) select] where:@"foo = 1"] order:DBOrderDescending by:@[@"index"]] toString],
                          @"SELECT * FROM `aTable` WHERE aTable.`foo` IS $1 ORDER BY `index` DESC");
    
    NSArray *fields = @[@"a", @"b", @"c"];
    XCTAssertEqualObjects([[Q(Select) select:fields] toString],
                          @"SELECT a, b, c FROM `aTable`", @"");
    
    NSDictionary *update = @{ @"a": @1, @"b": @2, @"c": @3 };
    XCTAssertEqualObjects([[Q(Update) update:update] toString],
                          @"UPDATE `aTable` SET `a`=$1, `b`=$2, `c`=$3");
    
    XCTAssertEqualObjects([[Q(Delete) delete] toString], @"DELETE FROM `aTable`", @"");

    NSArray *columns = @[
        [DBColumnDefinition columnWithName:@"identifier"
                            type:DBTypeText
                     constraints:@[[DBPrimaryKeyConstraint primaryKeyConstraintWithOrder:DBOrderAscending autoIncrement:NO onConflict:DBConflictActionFail]]],
        [DBColumnDefinition columnWithName:@"name"
                            type:DBTypeText
                     constraints:@[[DBNotNullConstraint new]]]
                         ];
    XCTAssertEqualObjects([[[[[DB new] create] table:@"tbl"] columns:columns] toString],
                          @"CREATE TABLE `tbl`(`identifier` TEXT PRIMARY KEY ASC ON CONFLICT FAIL, `name` TEXT NOT NULL)", @"");

    XCTAssertEqualObjects([Q(Drop) toString], @"DROP TABLE `aTable`");

    DBAlterQuery *alter = [Q(Alter) appendColumns:@[[DBColumnDefinition columnWithName:@"test" type:DBTypeText constraints:@[[DBNotNullConstraint new]]]]];
    XCTAssertEqualObjects([alter toString], @"ALTER TABLE `aTable` ADD COLUMN `test` TEXT NOT NULL");
}

@end
