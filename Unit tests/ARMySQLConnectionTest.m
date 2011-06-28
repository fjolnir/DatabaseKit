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
	NSLog(@"setup");
  self.connection = [super setUpMySQLFixtures];
	NSLog(@"done");
}
- (void)testSelect
{
	NSLog(@"test select");
  NSString *query = @"SELECT * FROM foobar";
	NSLog(@"%@", query);
  NSArray *result = [self.connection executeSQL:query substitutions:nil];
	NSLog(@"%@", result);
	
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
