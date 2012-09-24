//
//  SenTestCase+Fixtures.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 1.4.2008.
//  Copyright 2008 Fjölnir Ásgeirsson. All rights reserved.
//

#import "GHTestCase+Fixtures.h"
#import <DatabaseKit/DatabaseKit.h>

@implementation GHTestCase (Fixtures)
- (DBSQLiteConnection *)setUpSQLiteFixtures
{
  NSError *err = nil;
  NSString *path = [[NSBundle mainBundle] pathForResource:@"cleanDatabase" ofType:@"db"];

  NSString *fixtures = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sqlite_fixtures" ofType:@"sql"] 
                                                 encoding:NSUTF8StringEncoding 
                                                    error:nil];
	
	DBSQLiteConnection *connection = [DBSQLiteConnection openConnectionWithInfo:@{@"path": path}
																		  error:&err];
	for(NSString *query in [fixtures componentsSeparatedByString:@"\n"])
	{
        NSError *err = nil;
        [connection executeSQL:query substitutions:nil error:&err];
		if(err)
			NSLog(@"FIXTUREFAIL!(%@): %@", query,err);
	}
	// See if it works
  [DBBase setDefaultConnection:connection];

    DBQuery *q = [[DBTable withName:@"people"] select:@"*"];
    NSLog(@"%@", q[0]);

	return connection;
}

/*- (DBMySQLConnection *)setUpMySQLFixtures
{
  NSError *err = nil;
  NSMutableString *fixturePath = [NSMutableString stringWithUTF8String:__FILE__];
  [fixturePath replaceOccurrencesOfString:[fixturePath lastPathComponent] 
							   withString:@"mysql_fixtures.sql"
								  options:0
									range:NSMakeRange(0, [fixturePath length])];
   NSString *fixtures = [NSString stringWithContentsOfFile:fixturePath encoding:NSUTF8StringEncoding error:nil];
  DBMySQLConnection *connection = [DBMySQLConnection openConnectionWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:
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
	[DBBase setDefaultConnection:connection];
	
	return connection;
}*/
@end
