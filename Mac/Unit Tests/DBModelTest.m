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


@class TEAnimal, TEPerson;

@interface TEModel : DBModel
@property(readwrite, strong) NSString *name, *info;
@end
@interface TEModel (Accessors)
- (NSArray *)people;
- (void)setPeople:(NSArray *)people;
- (void)addPerson:(TEPerson *)person;
- (TEAnimal *)animal;
- (void)setAnimal:(TEAnimal *)animal;
@end

@interface TEPerson : DBModel {
    
}
@property(readwrite, weak) NSString *userName, *realName;
@end
@interface TEPerson (Accessors)
- (NSArray *)animals;
- (TEModel *)model;
- (NSArray *)belgians;
@end

@interface TEBelgian : DBModel {
    
}
@end
@interface TEBelgian (Accessors)
- (TEPerson *)person;
@end


@interface TEAnimal : DBModel {
    
}
@end
@interface TEAnimal (Accessors)
- (NSString *)species;
- (NSString *)nickname;
- (TEModel *)model;
- (void)setModel:(TEModel *)animal;
- (NSArray *)people;
- (void)addPerson:(TEPerson *)person;
@end


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
    NSUInteger theId = model.databaseId;
    XCTAssertTrue([model destroy], @"Couldn't delete record");
    NSArray *result = [[[db[@"models"] select] where:@{ @"id": @(theId) }] execute];
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
    [first beginTransaction];
    NSString *newName = @"NOT THE SAME NAME!";
    //[first setName:newName];
    first.name = @"NOT THE SAME NAME!";
    [first endTransaction];
    XCTAssertEqualObjects([first name] , newName , @"The new name apparently wasn't saved");
}

- (void)testHasMany
{
    // First test retrieving
    TEModel *model = [[[db[@"models"] select] limit:@1] first];
    NSArray *originalPeople = [model people];
    XCTAssertTrue(([originalPeople count] == 2), @"TEModel should have 2 TEPeople but had %lu", [originalPeople count]);

    // Then test sending
    TEPerson *aPerson = [[[db[@"people"] insert:@{@"realName": @"frankenstein", @"userName": @"frank"}] execute] firstObject];
    NSLog(@"inserted: %@ %@", aPerson, [aPerson class]);
    [model addPerson:aPerson];
    NSMutableArray *laterPeople = [originalPeople mutableCopy];
    [laterPeople addObject:aPerson];

    XCTAssertTrue([[model people] count] == [laterPeople count], @"person count should've been %lu but was %lu", [laterPeople count], [[model people] count]);

    [model setPeople:@[aPerson]];
    XCTAssertTrue([[model people] count] == 1, @"model should only have one person");
    XCTAssertTrue([[model people][0] databaseId] == [aPerson databaseId], @"person id should've been %lu but was %lu", [aPerson databaseId], [[model people][0] databaseId]);
}

- (void)testHasOne
{
    TEModel *model = [[[db[@"models"] select] limit:@1] first];
    TEModel *animal = [[[db[@"animals"] select] limit:@1] first];

    XCTAssertTrue(([animal databaseId] == [[model animal] databaseId]), @"%@ != %@ !!", animal, [model animal]);
    return;

    // Then test sending
    TEAnimal *anAnimal = [[[db[@"animals"] insert:@{@"species": @"Leopard", @"nickname": @"Godfried"}] execute] firstObject];

    [model setAnimal:anAnimal];
    XCTAssertTrue( ([[model animal] databaseId] == [anAnimal databaseId]), @"animal id was wrong (%lu != %lu)", [[model animal] databaseId], [anAnimal databaseId]);
}

- (void)testDelayedWriting
{
    [DBModel setDelayWriting:YES];
    TEModel *model = [[[db[@"models"] select] limit:@1] first];
    [model setName:@"delayed"];
    XCTAssertEqualObjects(@"a name", [model name], @"model name was saved prematurely!");
    [model save];
    XCTAssertEqualObjects(@"delayed", [model name], @"model name was not saved!");
    [DBModel setDelayWriting:NO];
}
@end

@implementation TEModel
@dynamic name, info;
+ (void)initialize
{
    [[self relationships] addObject:[DBRelationshipHasMany relationshipWithName:@"people"]];
    [[self relationships] addObject:[DBRelationshipHasOne relationshipWithName:@"animal"]];

}
@end

@implementation TEPerson
@dynamic userName, realName;
+ (void)initialize
{
    [[self relationships] addObject:[DBRelationshipHasMany relationshipWithName:@"belgians"]];
}

@end

@implementation TEAnimal
@end

@implementation TEBelgian
@end