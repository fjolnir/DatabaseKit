#import "DBUnitTestUtilities.h"
#import <DatabaseKit/DatabaseKit.h>

@interface FixtureGetter : NSObject
+ (NSString *)fixturesForDatabase:(NSString *)dbName;
@end
@implementation FixtureGetter
+ (NSString *)fixturesForDatabase:(NSString *)dbName
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *fileName = [NSString stringWithFormat:@"%@_fixtures", dbName];
    
    return [NSString stringWithContentsOfFile:[bundle pathForResource:fileName ofType:@"sql"]
                                     encoding:NSUTF8StringEncoding
                                        error:NULL];
}
@end


DB *DBSQLiteDatabaseForTesting()
{
    NSError *err = nil;
    DBSQLiteConnection *connection = [[DBSQLiteConnection alloc] initWithURL:nil
                                                                       error:&err];
    DB *db = [[DB alloc] initWithConnection:connection];

    NSString *fixtures = [FixtureGetter fixturesForDatabase:@"sqlite"];
    for(NSString *query in [fixtures componentsSeparatedByString:@"\n"])
    {
        err = nil;
        [db.connection executeSQL:query substitutions:nil error:&err];
        if(err)
            NSLog(@"FIXTUREFAIL!(%@): %@", query,err);
    }
    return db;
}

DB *DBPostgresDatabaseForTesting()
{
    NSError *err = nil;
    NSURL *url = [NSURL URLWithString:@"postgres://localhost/dbkit_test"];
    DBPostgresConnection *connection = [[DBPostgresConnection alloc] initWithURL:url
                                                                         error:&err];
    NSCAssert(connection, @"Please create a postgres database called 'dbkit_test' on localhost");
    DB *db = [[DB alloc] initWithConnection:connection];
    NSString *fixtures = [FixtureGetter fixturesForDatabase:@"postgres"];
    for(NSString *query in [fixtures componentsSeparatedByString:@"\n"])
    {
        err = nil;
        [db.connection executeSQL:query substitutions:nil error:&err];
        if(err)
            NSLog(@"FIXTUREFAIL!(%@): %@", query,err);
    }
    return db;
}