//
//  SenTestCase+Fixtures.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 1.4.2008.
//  Copyright 2008 Fjölnir Ásgeirsson. All rights reserved.
//

#import "GHTestCase+Fixtures.h"
#import <ActiveRecord/ActiveRecord.h>

@implementation GHTestCase (Fixtures)
- (ARSQLiteConnection *)setUpSQLiteFixtures
{
  NSError *err = nil;
  NSString *path = [[NSBundle mainBundle] pathForResource:@"cleanDatabase" ofType:@"db"];

  NSString *fixtures = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sqlite_fixtures" ofType:@"sql"] 
                                                 encoding:NSUTF8StringEncoding 
                                                    error:nil];
	
	ARSQLiteConnection *connection = [ARSQLiteConnection openConnectionWithInfo:[NSDictionary dictionaryWithObject:path forKey:@"path"]
																		  error:&err];
	for(NSString *query in [fixtures componentsSeparatedByString:@"\n"])
	{
		@try {
			[connection executeSQL:query substitutions:nil];
		}
		@catch (NSException * e) {
			NSLog(@"FIXTUREFAIL!(%@): %@", query,e);
		}
	}
	// See if it works
  [ARBase setDefaultConnection:connection];
	
	return connection;
}

/*- (ARMySQLConnection *)setUpMySQLFixtures
{
  NSError *err = nil;
  NSMutableString *fixturePath = [NSMutableString stringWithUTF8String:__FILE__];
  [fixturePath replaceOccurrencesOfString:[fixturePath lastPathComponent] 
							   withString:@"mysql_fixtures.sql"
								  options:0
									range:NSMakeRange(0, [fixturePath length])];
   NSString *fixtures = [NSString stringWithContentsOfFile:fixturePath encoding:NSUTF8StringEncoding error:nil];
  ARMySQLConnection *connection = [ARMySQLConnection openConnectionWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																			 @"127.0.0.1", @"host",
																			 @"activerecord", @"user",
																			 @"123", @"password",
																			 @"activerecord_test", @"database",
																			 [NSNumber numberWithInt:3306], @"port", nil]
																	  error:&err];
	GHAssertNil(err, @"There was an error connecting to MySQL");
  if(err != nil)
    return nil;
	
	for(NSString *query in [fixtures componentsSeparatedByString:@"\n"])
	{
		@try {
			[connection executeSQL:query substitutions:nil];
		}
		@catch (NSException * e) {
			NSLog(@"FIXTUREFAIL!(%@): %@", query,e);
		}
	}
	// See if it works
	[ARBase setDefaultConnection:connection];
	
	return connection;
}*/
@end
