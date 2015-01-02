@import XCTest;
@import DatabaseKit;
#import "DBUnitTestUtilities.h"

@interface DBSQLiteConnectionTest : XCTestCase
@end

@implementation DBSQLiteConnectionTest {
    DB *db;
}

- (void)setUp
{
    db = DBSQLiteDatabaseForTesting();
}

- (void)tearDown
{
    XCTAssertTrue([db.connection closeConnection:NULL], @"Couldn't close connection");
}

- (void)testConnection
{
    XCTAssertNotNil(db.connection, @"connection should not be nil");
}

- (void)testFetchColumns
{
    // Test if we fetch correct columns
    NSArray *columnsFromDb = [[db.connection columnsForTable:@"foo"] allKeys];
    NSArray *columnsFixture = @[kDBUUIDColumn, @"bar", @"baz", @"integer"];
    for(NSString *fixture in columnsFixture)
    {
        XCTAssertTrue([columnsFromDb containsObject:fixture],
                     @"Columns didn't contain: %@", fixture);
    }
}

- (void)testQuery
{
    NSString *query = @"SELECT * FROM foo";
    NSArray *result = [[db.connection execute:query substitutions:nil error:NULL] toArray:NULL];
    XCTAssertTrue([result count] == 2, @"foo should have 2 rows");
    NSArray *columns = [result[0] allKeys];
    NSArray *expectedColumns = @[kDBUUIDColumn, @"bar", @"baz", @"integer"];
    for(NSString *fixture in expectedColumns)
    {
        XCTAssertTrue([columns containsObject:fixture],
                     @"Columns didn't contain: %@", fixture);
    }

    XCTAssertEqual([db[@"foo"] count], 2, @"Fast enumeration did not evaluate the correct amount of times");
}

@end
