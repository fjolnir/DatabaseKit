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
- (DB *)setUpSQLiteFixtures
{
    NSError *err = nil;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"cleanDatabase" ofType:@"db"];
    NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"sqlite://%@", path] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *fixtures = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sqlite_fixtures" ofType:@"sql"]
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];
    NSLog(@"%@ %@", url, path);
    DB *db = [DB withURL:url error:&err];
    for(NSString *query in [fixtures componentsSeparatedByString:@"\n"])
    {
        NSError *err = nil;
        [db.connection executeSQL:query substitutions:nil error:&err];
        if(err)
            NSLog(@"FIXTUREFAIL!(%@): %@", query,err);
    }

    return db;
}
@end
