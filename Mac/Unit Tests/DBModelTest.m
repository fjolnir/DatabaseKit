#import <XCTest/XCTest.h>
#import <DatabaseKit/DatabaseKit.h>
#import "DBUnitTestUtilities.h"
#import "DBModelTest.h"

@class TEAnimal, TEPerson;

@interface DBModelTest : XCTestCase {
    DB *db;
}
@end

@implementation DBModel (PrefixSetter)
+ (void)load
{
    [self setClassPrefix:@"TE"]; // TE stands for test fyi
}
@end

@implementation DBModelTest
- (void)setUp
{
    db = DBSQLiteDatabaseForTesting();

    NSError *err;
    if(![db migrateModelClasses:@[[TEModel class], [TEPerson class], [TEWebSite class], [TEAnimal class]]
                          error:&err]) {
        NSLog(@"Failed to initialize models: %@", err);
    }

    TEModel *testModel = [TEModel modelInDatabase:db];
    testModel.name = @"Foobar";
    testModel.info = @"lorem ipsum";
    [testModel save];
}

- (void)testTableName
{
    XCTAssertTrue([@"models" isEqualToString:[TEModel tableName]],
                 @"TEModel's table name shouldn't be: %@", [TEModel tableName]);
}

- (void)testDestroy
{
    TEModel *model = [[db[@"models"] select] firstObject];
    //[[[db[@"models"] insert:@{@"name": @"Deletee", @"info": @"This won't exist for long"}] execute] firstObject];
    NSString *theId = model.identifier;
    XCTAssertTrue([model destroy], @"Couldn't delete record");
    NSArray *result = [[[db[@"models"] select] where:@"%K = %@", kDBIdentifierColumn, theId] execute];
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
    [first.table.database.connection beginTransaction];
    NSString *newName = @"NOT THE SAME NAME!";
    first.name = newName;
    [first.table.database.connection endTransaction];
    XCTAssertEqualObjects([first name] , newName , @"The new name apparently wasn't saved");
}

- (void)testNSCoding
{
    TEWebSite *site = [TEWebSite modelInDatabase:db];
    site.url = [NSURL URLWithString:@"http://google.com"];
    XCTAssert([site save], @"Unable to save NSCoding compliant object to database");
    TEWebSite *retrievedSite = [[db[[TEWebSite tableName]] select] firstObject];
    XCTAssertEqualObjects(site.url, retrievedSite.url);
}

- (void)testUniqing
{
    TEModel *firstA = [[db[@"models"] select] firstObject];
    TEModel *firstB = [[db[@"models"] select] firstObject];
    XCTAssertEqual(firstA, firstB);
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
