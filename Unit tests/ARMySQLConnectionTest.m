//
//  ARMySQLConnectionTest.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 18.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import "ARMySQLConnectionTest.h"
#import "ARMySQLConnection.h"
#import "SenTestCase+Fixtures.h"

@implementation ARMySQLConnectionTest
@synthesize connection;
- (void)setUp
{
  self.connection = [super setUpMySQLFixtures];
}
- (void)testSelect
{
  NSString *query = @"SELECT * FROM foobar";
  NSArray *result = [self.connection executeSQL:query substitutions:nil];

	STAssertEqualObjects([[result objectAtIndex:0] objectForKey:@"name"], @"a name", @"Invalid name retrieved from mysql");
}
- (void)testInsert
{
  NSString *query = @"INSERT INTO `foobar` (`name`,`info`) VALUES ('insert test','none')";
  NSArray *result = [self.connection executeSQL:query substitutions:nil];
	
	// Do a select to see if it worked
	query = @"SELECT * FROM foobar";
  result = [self.connection executeSQL:query substitutions:nil];
	STAssertEqualObjects([[result objectAtIndex:2] objectForKey:@"name"], @"insert test", @"Invalid name retrieved from mysql after insertion");
}
@end
