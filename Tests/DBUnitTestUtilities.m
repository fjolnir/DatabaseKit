@import DatabaseKit;
#import "DBUnitTestUtilities.h"

@interface FixtureGetter : NSObject
@end

@implementation FixtureGetter
+ (NSString *)fixturesForDatabase:(NSString *)dbName
{
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSString *fileName = [NSString stringWithFormat:@"%@_fixtures", dbName];
    
    return [NSString stringWithContentsOfFile:[bundle pathForResource:fileName ofType:@"sql"]
                                     encoding:NSUTF8StringEncoding
                                        error:NULL];
}
@end


DB *DBSQLiteDatabaseForTesting()
{
    NSError *err = nil;
    DBSQLiteConnection *connection = [[DBSQLiteConnection alloc] initWithURL:[NSURL URLWithString:@"sqlite://test?mode=memory"]
                                                                       error:&err];
    DB *db = [[DB alloc] initWithConnection:connection];

    NSString *fixtures = [FixtureGetter fixturesForDatabase:@"sqlite"];
    for(NSString *query in [fixtures componentsSeparatedByString:@"\n"])
    {
        err = nil;
        DBResult *result = [db.connection execute:query substitutions:nil error:&err];
        while([result step:&err] == DBResultStateNotAtEnd);
        if(err)
            NSLog(@"FIXTUREFAIL!(%@): %@", query,err);
    }
    return db;
}
