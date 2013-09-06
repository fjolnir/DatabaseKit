//
//  SenTestCase+Fixtures.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 1.4.2008.
//  Copyright 2008 Fjölnir Ásgeirsson. All rights reserved.
//

#import "DBUnitTestUtilities.h"
#import <DatabaseKit/DatabaseKit.h>

@interface DummyClass : NSObject
@end
@implementation DummyClass
@end
DB *DBSQLiteDatabaseForTesting()
{
    NSBundle *bundle = [NSBundle bundleForClass:[DummyClass class]];
    NSString *fixtures = [NSString stringWithContentsOfFile:[bundle pathForResource:@"sqlite_fixtures" ofType:@"sql"]
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];
    
    NSError *err = nil;
    DB *db = [[DB alloc] initWithConnection:[[DBSQLiteConnection alloc] initWithURL:nil error:&err]];

    for(NSString *query in [fixtures componentsSeparatedByString:@"\n"])
    {
        err = nil;
        [db.connection executeSQL:query substitutions:nil error:&err];
        if(err)
            NSLog(@"FIXTUREFAIL!(%@): %@", query,err);
    }

    return db;
}
