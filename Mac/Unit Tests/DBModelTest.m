//
//  DBModelTest.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

// TODO: Reset database for each test. (maybe use in memory database and fixtures)

#import "DBModelTest.h"
#import <DatabaseKit/DatabaseKit.h>
#import "GHTestCase+Fixtures.h"

@implementation DBModel (PrefixSetter)
+ (void)load
{
    [self setClassPrefix:@"TE"]; // TE stands for test fyi
}
@end

@implementation DBModelTest
- (void)setUp
{
    db = [super setUpSQLiteFixtures];
}

- (void)testTableName
{
    GHAssertTrue([@"models" isEqualToString:[TEModel tableName]],
                 @"TEModel's table name shouldn't be: %@", [TEModel tableName]);
}

- (void)testCreate
{
    TEModel *model = [db[@"models"] insert:@{@"name": @"Foobar", @"info": @"This is great!"}][0];

    GHAssertEqualObjects(@"Foobar", [model name], @"Couldn't create model!");
    GHAssertEqualObjects(@"This is great!", [model info], @"Couldn't create model!");
}

- (void)testDestroy
{
    TEModel *model = [db[@"models"] insert:@{@"name": @"Deletee", @"info": @"This won't exist for long"}][0];
    NSUInteger theId = model.databaseId;
    GHAssertTrue([model destroy], @"Couldn't delete record");
    NSArray *result = [[[db[@"models"] select] where:@{ @"id": @(theId) }] execute];
    GHAssertEquals([result count], (NSUInteger)0, @"The record wasn't actually deleted result: %@", result);
}

- (void)testFindFirst
{
    TEModel *first = [[[db[@"models"] select] limit:@1] first];

    GHAssertNotNil(first, @"No result for first entry!");
    GHAssertEqualObjects(@"a name", [first name] , @"The name of the first entry should be 'a name'");
}

- (void)testModifying
{
    TEModel *first = [[[db[@"models"] select] limit:@1] first];
    [first beginTransaction];
    NSString *newName = @"NOT THE SAME NAME!";
    //[first setName:newName];
    first.name = @"NOT THE SAME NAME!";
    [first endTransaction];
    GHAssertEqualObjects([first name] , newName , @"The new name apparently wasn't saved");
}

- (void)testHasMany
{
    // First test retrieving
    TEModel *model = [[[db[@"models"] select] limit:@1] first];
    NSArray *originalPeople = [model people];
    GHAssertTrue(([originalPeople count] == 2), @"TEModel should have 2 TEPeople but had %d", [originalPeople count]);

    // Then test sending
    TEPerson *aPerson = [db[@"people"] insert:@{@"realName": @"frankenstein", @"userName": @"frank"}][0];
    [model addPerson:aPerson];
    NSMutableArray *laterPeople = [originalPeople mutableCopy];
    [laterPeople addObject:aPerson];

    GHAssertTrue([[model people] count] == [laterPeople count], @"person count should've been %d but was %d", [laterPeople count], [[model people] count]);

    [model setPeople:@[aPerson]];
    GHAssertTrue([[model people] count] == 1, @"model should only have one person");
    GHAssertTrue([[model people][0] databaseId] == [aPerson databaseId], @"person id should've been %d but was %d", [aPerson databaseId], [[model people][0] databaseId]);
}

- (void)testHasManyThrough
{
    // First test retrieving
    TEModel *model = [[[db[@"models"] select] limit:@1] first];
    NSArray *belgians = [model belgians];
    NSLog(@"belgians: %@", belgians);
    GHAssertTrue(([belgians count] == 2), @"TEModel should have 2 belgians but had %d", [belgians count]);
}

- (void)testHasOne
{
    TEModel *model = [[[db[@"models"] select] limit:@1] first];
    TEModel *animal = [[[db[@"animals"] select] limit:@1] first];

    GHAssertTrue(([animal databaseId] == [[model animal] databaseId]), @"%@ != %@ !!", animal, [model animal]);
    return;

    // Then test sending
    TEAnimal *anAnimal = [db[@"animals"] insert:@{@"species": @"Leopard", @"nickname": @"Godfried"}][0];

    [model setAnimal:anAnimal];
    GHAssertTrue( ([[model animal] databaseId] == [anAnimal databaseId]), @"animal id was wrong (%d != %d)", [[model animal] databaseId], [anAnimal databaseId]);
}

- (void)testBelongsTo
{
    NSLog(@"%@ %@", db, db[@"people"]);
    TEPerson *person = [[[db[@"people"] select] limit:@1] first];
    TEModel *model = [person model];

    GHAssertNotNil(model, @"No model found for person!");

    // Then test sending
    TEAnimal *anAnimal = [db[@"animals"] insert:@{@"species": @"cheetah", @"nickname": @"rick"}][0];

    TEAnimal *oldAnimal = [model animal];
    [anAnimal setModel:model];

    GHAssertTrue(([[anAnimal model] databaseId] == [model databaseId]), @"model id was wrong (%d != %d)", [[anAnimal model] databaseId], [model databaseId]);
    [model setAnimal:oldAnimal];
}

- (void)testHasAndBelongsToMany
{
    TEPerson *person = db[@"people"][3];
    TEModel *animal = [[[db[@"animals"] select] limit:@1] first];
    GHAssertEquals([[person animals][0] databaseId], (NSUInteger)1, @"Person had wrong animal!");
    GHAssertEquals([[animal people][0] databaseId], (NSUInteger)3, @"Animal had wrong person!");
    animal = db[@"animals"][2];
    [animal addPerson:person];
    GHAssertEquals([[animal people][0] databaseId], (NSUInteger)[person databaseId], @"Animal had wrong person!");
}

- (void)testDelayedWriting
{
    [DBModel setDelayWriting:YES];
    TEModel *model = [[[db[@"models"] select] limit:@1] first];
    [model setName:@"delayed"];
    GHAssertEqualObjects(@"a name", [model name], @"model name was saved prematurely!");
    [model save];
    GHAssertEqualObjects(@"delayed", [model name], @"model name was not saved!");
    [DBModel setDelayWriting:NO];
}
@end

@implementation TEModel
@dynamic name, info;
+ (void)initialize
{
    [[self relationships] addObject:[DBRelationshipHasMany relationshipWithName:@"people"]];
    [[self relationships] addObject:[DBRelationshipHasOne relationshipWithName:@"animal"]];
    [[self relationships] addObject:[DBRelationshipHasManyThrough relationshipWithName:@"belgians" through:@"people"]];

}
@end

@implementation TEPerson
@dynamic userName, realName;
+ (void)initialize
{
    [[self relationships] addObject:[DBRelationshipBelongsTo relationshipWithName:@"model"]];
    [[self relationships] addObject:[DBRelationshipHABTM relationshipWithName:@"animals"]];
    [[self relationships] addObject:[DBRelationshipHasMany relationshipWithName:@"belgians"]];
}

@end

@implementation TEAnimal
+ (void)initialize
{
    [[self relationships] addObject:[DBRelationshipBelongsTo relationshipWithName:@"model"]];
    [[self relationships] addObject:[DBRelationshipHABTM relationshipWithName:@"people"]];
}
@end

@implementation TEBelgian
+ (void)initialize
{
    [[self relationships] addObject:[DBRelationshipBelongsTo relationshipWithName:@"person"]];
}
@end