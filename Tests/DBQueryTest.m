@import XCTest;
@import DatabaseKit;
#import "DBUnitTestUtilities.h"

@interface DBQueryTest : XCTestCase

@end

#define Q(type) [DB##type##Query withTable:[DBTable withDatabase:[DB new] name:@"aTable"]]

@implementation DBQueryTest {
    DB *db;
}
- (void)setUp
{
    db = DBSQLiteDatabaseForTesting();
}


- (void)testBuilding
{
    XCTAssertEqualObjects([[[[Q(Select) select] where:@"foo = 1"] order:DBOrderDescending by:@[@"index"]] toString],
                          @"SELECT * FROM `aTable` WHERE aTable.`foo` IS $1 ORDER BY `index` DESC");
    
    NSArray *columns = @[@"a", @"b", @"c"];
    XCTAssertEqualObjects([[Q(Select) select:columns] toString],
                          @"SELECT a, b, c FROM `aTable`", @"");
    
    NSDictionary *update = @{ @"a": @1, @"b": @2, @"c": @3 };
    XCTAssertEqualObjects([[Q(Update) update:update] toString],
                          @"UPDATE `aTable` SET `a`=$1, `b`=$2, `c`=$3");
    
    XCTAssertEqualObjects([[Q(Delete) delete] toString], @"DELETE FROM `aTable`", @"");

    NSArray *columnDefinitions = @[
        [DBColumnDefinition columnWithName:kDBIdentifierColumn
                            type:DBTypeText
                     constraints:@[[DBPrimaryKeyConstraint primaryKeyConstraintWithOrder:DBOrderAscending autoIncrement:NO onConflict:DBConflictActionFail]]],
        [DBColumnDefinition columnWithName:@"name"
                            type:DBTypeText
                     constraints:@[[DBNotNullConstraint new]]]
                         ];
    XCTAssertEqualObjects([[[[[DB new] create] table:@"tbl"] columns:columnDefinitions] toString],
                          @"CREATE TABLE `tbl`(`identifier` TEXT PRIMARY KEY ASC ON CONFLICT FAIL, `name` TEXT NOT NULL)", @"");

    XCTAssertEqualObjects([Q(DropTable) toString], @"DROP TABLE `aTable`");

    DBAlterTableQuery *alter = [Q(AlterTable) appendColumns:@[[DBColumnDefinition columnWithName:@"test" type:DBTypeText constraints:@[[DBNotNullConstraint new]]]]];
    XCTAssertEqualObjects([alter toString], @"ALTER TABLE `aTable` ADD COLUMN `test` TEXT NOT NULL");
}

- (void)testFastEnumeration
{
    NSUInteger count = [[db[@"foo"] select] count];
    NSUInteger i = 0;
    for(__unused NSDictionary *row in [db[@"foo"] select]) {
        ++i;
    }
    XCTAssertEqual(count, i);
}

@end
