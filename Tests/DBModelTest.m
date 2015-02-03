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

    TEModel *testModel = [TEModel new];
    testModel.name = @"Foobar";
    testModel.info = @"lorem ipsum";
    [db registerObject:testModel];
    [db saveObjects:NULL];
}

- (void)testTableName
{
    XCTAssertTrue([@"models" isEqualToString:[TEModel tableName]],
                 @"TEModel's table name shouldn't be: %@", [TEModel tableName]);
}

- (void)testInsert
{
    TEModel *model = [TEModel new];
    model.name = @"Foo";
    [db registerObject:model];
    [db saveObjects:NULL];
    
    TEModel *retrievedModel = [[[db[@"models"] select] where:@"UUID=%@", model.UUID] firstObject];
    XCTAssertEqualObjects(retrievedModel.UUID, model.UUID);
    XCTAssertEqualObjects(retrievedModel.name, model.name);
}

- (void)testDestroy
{
    TEModel *model = [[db[@"models"] select] firstObject];
    NSUUID *theId = model.UUID;
    [db removeObject:model];
    NSArray *result = [[[db[@"models"] select] where:@"%K = %@", kDBUUIDKey, theId] execute:NULL];
    XCTAssertEqual(result.count, (NSUInteger)0, @"The record wasn't actually deleted result: %@", result);
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
    TEWebSite *site = [TEWebSite new];
    [db registerObject:site];
    site.url = [NSURL URLWithString:@"http://google.com"];
    XCTAssert([db saveObjects:NULL], @"Unable to save NSCoding compliant object to database");
    TEWebSite *retrievedSite = [[db[[TEWebSite tableName]] select] firstObject];
    XCTAssertEqualObjects(site.url, retrievedSite.url);
}

- (void)testSingularRelationships
{
    TEPerson *john = [TEPerson new];
    john.name = @"John Smith";
    TEAnimal *fido = [TEAnimal new];
    fido.name = @"Fido";
    john.pet = fido;
    
    [db registerObject:john];
    [db registerObject:fido];
    [db saveObjects:NULL];

    TEPerson *johnFetched = [[db[@"people"] where:@"name=%@", john.name] firstObject];
    XCTAssertEqualObjects(johnFetched.pet.name, john.pet.name);
}

- (void)testPluralRelationships
{
    TEPerson *john = [TEPerson new];
    john.name = @"John Smith";
    TEAnimal *fido = [TEAnimal new];
    fido.name = @"Fido";
    TEAnimal *clarus = [TEAnimal new];
    clarus.name = @"Clarus";
    
    john.pets = [NSSet setWithObjects:fido, clarus, nil];
    [db registerObject:john];
    [db registerObject:fido];
    [db registerObject:clarus];
    [db saveObjects:NULL];
    
    TEPerson *johnFetched = [[db[@"people"] where:@"name=%@", john.name] firstObject];
    XCTAssertEqualObjects(johnFetched.pets, john.pets);
}

- (void)testRelationshipPredicate
{
    TEPerson *john = [TEPerson new];
    john.name = @"John Smith";
    TEAnimal *fido = [TEAnimal new];
    fido.name = @"Fido";
    TEAnimal *clarus = [TEAnimal new];
    clarus.name = @"Clarus";
    
    john.pets = [NSSet setWithObjects:fido, clarus, nil];
    [db registerObject:john];
    [db registerObject:fido];
    [db registerObject:clarus];
    [db saveObjects:NULL];
    
    TEPerson *johnFetched = [[db[@"people"] where:@"name=%@", john.name] firstObject];
    NSSet *fidoSet = [johnFetched valueForKey:@"pets"
                            matchingPredicate:[NSPredicate predicateWithFormat:@"name=%@", fido.name]];
    XCTAssertEqual(fidoSet.count, 1);
    XCTAssertEqualObjects(fido, fidoSet.anyObject);
    
    NSArray *emptyArray = [johnFetched valueForKey:@"pets"
                                matchingPredicate:[NSPredicate predicateWithFormat:@"name=\"Foobar\""]];
    XCTAssertEqual(emptyArray.count, 0);
}

- (void)testJSONInit
{
    NSDictionary *JSONObject = @{ @"identifier": [[NSUUID UUID] UUIDString],
                                  @"name": @"Clarus",
                                  @"species": @"Dogcow" };
    
    TEAnimal *clarus = [[TEAnimal alloc] initWithJSONObject:JSONObject];
    XCTAssertEqualObjects(clarus.UUID.UUIDString, JSONObject[@"identifier"]);
    XCTAssertEqualObjects(clarus.name, JSONObject[@"name"]);
    XCTAssertEqualObjects(clarus.species, JSONObject[@"species"]);
}

- (void)testJSONRelationship
{
    NSDictionary *JSONObject = @{ @"identifier": [[NSUUID UUID] UUIDString],
                                  @"name": @"John Smith",
                                  @"pet": @{ @"identifier": [[NSUUID UUID] UUIDString],
                                             @"name": @"Clarus",
                                             @"species": @"Dogcow" }
                                  };
    
    TEPerson *john = [[TEPerson alloc] initWithJSONObject:JSONObject];
    TEAnimal *clarus = john.pet;
    XCTAssertEqualObjects(john.UUID.UUIDString, JSONObject[@"identifier"]);
    XCTAssertEqualObjects(john.name, JSONObject[@"name"]);
    XCTAssertEqualObjects(clarus.UUID.UUIDString, JSONObject[@"pet"][@"identifier"]);
    XCTAssertEqualObjects(clarus.name, JSONObject[@"pet"][@"name"]);
    XCTAssertEqualObjects(clarus.species, JSONObject[@"pet"][@"species"]);
}

@end

@implementation TEModel
@end

@implementation TEPerson
+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{ @"UUID": @"identifier",
              @"name": @"name",
              @"pet": @"pet" };
}
@end

@implementation TEAnimal
+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{ @"UUID": @"identifier",
              @"name": @"name",
              @"species": @"species" };
}
@end

@implementation TEWebSite
@end
