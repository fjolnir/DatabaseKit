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
    
    NSDictionary *carCols = [db.connection columnsForTable:[TECar tableName]];
    XCTAssertEqual([carCols[@"identifier"] intValue], DBTypeText);
    XCTAssertEqual([carCols[@"brandName"] intValue], DBTypeText);
    XCTAssertEqual([carCols[@"yearBuilt"] intValue], DBTypeInteger);
    NSDictionary *doorCols = [db.connection columnsForTable:[TEDoor tableName]];
    XCTAssertEqual([doorCols[@"identifier"] intValue], DBTypeText);
    XCTAssertEqual([doorCols[@"carIdentifier"] intValue],DBTypeText);
    XCTAssertEqual([doorCols[@"side"] intValue], DBTypeInteger);
}

- (void)testMigrating
{
    NSError *err;
    NSArray *old = @[[TECar class], [TEDoor class]];
    NSArray *new  = @[[TECarChanged class], [TEDoor class]];
    XCTAssert([db migrateModelClasses:old error:&err],
              @"Failed to initialize models: %@", err);

    XCTAssert([db migrateModelClasses:new error:&err],
              @"Failed to initialize models: %@", err);

    NSSet *migratedColumns = [NSSet setWithObjects:@"identifier", @"color", @"yearBuilt", nil];
    XCTAssertEqualObjects([NSSet setWithArray:[[db.connection columnsForTable:[TECar tableName]] allKeys]],
                          migratedColumns);

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
+ (NSArray *)indices
{
    return @[[DBIndex indexWithName:@"brandIdx" onColumns:@[@"brandName"] unique:YES]];
}
@end
@implementation TECarChanged

+ (NSString *)tableName
{
    return @"cars";
}

+ (NSArray *)indices
{
    return @[[DBIndex indexWithName:@"colorIdx" onColumns:@[@"color"] unique:NO]];
}

@end
@implementation TEDoor
@end
