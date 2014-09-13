//
//  DBModelTest.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  CopyriXCTt 2007 Fjölnir Ásgeirsson. All riXCTts reserved.
//

// TODO: Reset database for each test. (maybe use in memory database and fixtures)

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
}

- (void)testTableName
{
    XCTAssertTrue([@"models" isEqualToString:[TEModel tableName]],
                 @"TEModel's table name shouldn't be: %@", [TEModel tableName]);
}

- (void)testCreate
{
    TEModel *model = [[[db[@"models"] insert:@{@"name": @"Foobar", @"info": @"This is great!"}] execute] firstObject];

    XCTAssertEqualObjects(@"Foobar", [model name], @"Couldn't create model!");
    XCTAssertEqualObjects(@"This is great!", [model info], @"Couldn't create model!");
}

- (void)testDestroy
{
    TEModel *model = [[[db[@"models"] insert:@{@"name": @"Deletee", @"info": @"This won't exist for long"}] execute] firstObject];
    NSString *theId = model.identifier;
    XCTAssertTrue([model destroy], @"Couldn't delete record");
    NSArray *result = [[[db[@"models"] select] where:@{ @"identifier": theId }] execute];
    XCTAssertEqual([result count], (NSUInteger)0, @"The record wasn't actually deleted result: %@", result);
}

- (void)testFindFirst
{
    TEModel *first = [[[db[@"models"] select] limit:@1] first];

    XCTAssertNotNil(first, @"No result for first entry!");
    XCTAssertEqualObjects(@"a name", [first name] , @"The name of the first entry should be 'a name'");
}

- (void)testModifying
{
    TEModel *first = [[[db[@"models"] select] limit:@1] first];
    [first.table.database.connection beginTransaction];
    NSString *newName = @"NOT THE SAME NAME!";
    //[first setName:newName];
    first.name = @"NOT THE SAME NAME!";
    [first.table.database.connection endTransaction];
    XCTAssertEqualObjects([first name] , newName , @"The new name apparently wasn't saved");
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