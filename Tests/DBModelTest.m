@import XCTest;
@import DatabaseKit;
#import "DBUnitTestUtilities.h"
#import "DBModelTest.h"

@interface DBModelTest : XCTestCase
@end

@implementation DBModelTest {
    DB *db;
}

- (void)setUp
{
    db = DBSQLiteDatabaseForTesting();

    NSError *err;
     if(![db migrateSchema:&err]) {
        NSLog(@"Failed to initialize models: %@", err);
    }

    TEModel *testModel = [[TEModel alloc] initWithDatabase:db];
    testModel.name = @"Foobar";
    testModel.info = @"lorem ipsum";
    [db saveObjects:NULL];
}

- (void)testTableName
{
    XCTAssertTrue([@"models" isEqualToString:[TEModel tableName]],
                 @"TEModel's table name shouldn't be: %@", [TEModel tableName]);
}

- (void)testDestroy
{
    TEModel *model = [[db[@"models"] select] firstObject];
    NSString *theId = model.identifier;
    [db deleteObject:model];
    NSArray *result = [[[db[@"models"] select] where:@"%K = %@", kDBIdentifierColumn, theId] execute:NULL];
    XCTAssertEqual([result count], (NSUInteger)0, @"The record wasn't actually deleted result: %@", result);
}

- (void)testFindFirst
{
    TEModel *first = [[db[@"models"] select] firstObject];

    XCTAssertNotNil(first, @"No result for first entry!");
    XCTAssertEqualObjects(@"Foobar", [first name] , @"The name of the first entry should be 'Foobar'");
}

- (void)testModifying
{
    TEModel *first = [[db[@"models"] select] firstObject];
    NSString *newName = @"NOT THE SAME NAME!";
    [first.database.connection transaction:^{
        first.name = newName;
        return DBTransactionCommit;
    }];
    XCTAssertEqualObjects([first name] , newName , @"The new name apparently wasn't saved");
}

- (void)testNSCoding
{
    TEWebSite *site = [[TEWebSite alloc] initWithDatabase:db];
    site.url = [NSURL URLWithString:@"http://google.com"];
    XCTAssert([db saveObjects:NULL], @"Unable to save NSCoding compliant object to database");
    TEWebSite *retrievedSite = [[db[[TEWebSite tableName]] select] firstObject];
    XCTAssertEqualObjects(site.url, retrievedSite.url);
}

@end

@implementation TEModel
@end

@implementation TEPerson
@end

@implementation TEAnimal
@end

@implementation TEWebSite
@end
