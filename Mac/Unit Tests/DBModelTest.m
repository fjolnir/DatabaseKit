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
    if(![db migrateModelClasses:@[[TEModel class], [TEPerson class], [TEBelgian class], [TEAnimal class]]
                          error:&err]) {
        NSLog(@"Failed to initialize models: %@", err);
    }

    TEModel *testModel = [[TEModel alloc] initWithDatabase:db];
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
    //[first setName:newName];
    first.name = @"NOT THE SAME NAME!";
    [first.table.database.connection endTransaction];
    XCTAssertEqualObjects([first name] , newName , @"The new name apparently wasn't saved");
}

- (void)testTableInitialization
{
    NSError *err;
    [db migrateModelClasses:@[[TECar class], [TEDoor class]] error:&err];
    NSLog(@"%@", [db.connection columnsForTable:[TECar tableName]]);
    NSDictionary *carCols = [db.connection columnsForTable:[TECar tableName]];
    XCTAssertEqualObjects(carCols[@"identifier"], @"TEXT");
    XCTAssertEqualObjects(carCols[@"brandName"], @"TEXT");
    XCTAssertEqualObjects(carCols[@"yearBuilt"], @"INTEGER");
    NSDictionary *doorCols = [db.connection columnsForTable:[TEDoor tableName]];
    XCTAssertEqualObjects(doorCols[@"identifier"], @"TEXT");
    XCTAssertEqualObjects(doorCols[@"carIdentifier"], @"TEXT");
    XCTAssertEqualObjects(doorCols[@"side"], @"INTEGER");
}

@end

@implementation TEModel
@end

@implementation TEPerson
@end

@implementation TEAnimal
@end

@implementation TEBelgian
@end

@implementation TECar
+ (NSArray *)constraintsForKey:(NSString *)key
{
    if([key isEqualToString:@"brandName"])
        return @[[DBNotNullConstraint new]];
    else
        return nil;
}
@end

@implementation TEDoor
@end
