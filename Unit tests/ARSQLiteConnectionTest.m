//
//  ARSQLiteConnectionTest.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import "ARSQLiteConnectionTest.h"
#import <ActiveRecord/ActiveRecord.h>
#import "SenTestCase+Fixtures.h"

@implementation ARSQLiteConnectionTest
- (void)setUp
{
	[connection release];
	connection = [[super setUpSQLiteFixtures] retain];
}

- (void)tearDown
{
  GHAssertTrue([connection closeConnection], @"Couldn't close connection");
}

- (void)testConnection
{
  GHAssertNotNil(connection, @"connection should not be nil");
}
- (void)testFetchColumns
{
  // Test if we fetch correct columns
  NSArray *columnsFromDb = [connection columnsForTable:@"foo"];
  NSArray *columnsFixture = [NSArray arrayWithObjects:@"id", @"bar", @"baz", @"integer", nil];
  for(NSString *fixture in columnsFixture)
  {
    GHAssertTrue([columnsFromDb containsObject:fixture],
                 @"Columns didn't contain: %@", fixture);
  }
}
- (void)testQuery
{
  NSString *query = @"SELECT * FROM foo" ;
  NSArray *result = [connection executeSQL:query substitutions:nil];
  GHAssertTrue([result count] == 2, @"foo should have 2 rows");
  NSArray *columns = [[result objectAtIndex:0] allKeys];
  NSArray *expectedColumns = [NSArray arrayWithObjects:@"id", @"bar", @"baz", @"integer", nil];
  for(NSString *fixture in expectedColumns)
  {
    GHAssertTrue([columns containsObject:fixture],
                 @"Columns didn't contain: %@", fixture);
  }
}
@end
