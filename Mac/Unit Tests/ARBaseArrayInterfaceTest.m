//
//  ARBaseArrayInterfaceTest.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 23.8.2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ARBaseArrayInterfaceTest.h"
#import <ActiveRecord/ActiveRecord.h>
#import "GHTestCase+Fixtures.h"
#import "ARBaseTest.h"

@interface TEModelArrayInterface : ARBaseArrayInterface
{
	
}
@end
@implementation TEModelArrayInterface


@end

@implementation ARBaseArrayInterfaceTest
- (void)setUp
{
	[super setUpSQLiteFixtures];
	//[super setUpMySQLFixtures];
	arr = [TEModelArrayInterface find:ARFindAll];
}
- (void)testCount
{
	GHAssertEquals([arr count], [[TEModel find:ARFindAll] count], @"array interface count should match lookup count");
}
- (void)testRetrieval
{
	GHAssertEquals([[arr objectAtIndex:1] databaseId], [[[TEModel find:ARFindAll] objectAtIndex:1] databaseId], @"Wrong result fetched");
	NSArray *infos = [arr valueForKey:@"info"];
	for(int i = 0; i < [infos count]; ++i)
	{
		GHAssertEqualObjects([infos objectAtIndex:i], [[[TEModel find:ARFindAll] objectAtIndex:i] info], @"valueForKey failed!");
	}
}
- (void)testWriting
{
	[arr setValue:@"testing 1 2 3.." forKey:@"info"];
	for(TEModel *record in [arr allObjects])
	{
		GHAssertEqualObjects(record.info, @"testing 1 2 3..", @"setValue:forKey failed!");
	}
}
@end
