#import "DB.h"
#import "DBTable.h"

@interface DB ()
@property(readwrite, strong) DBConnection *connection;
@end

@implementation DB

+ (DB *)withURL:(NSURL *)URL
{
    return [self withURL:URL error:nil];
}

+ (DB *)withURL:(NSURL *)URL error:(NSError **)err
{
    DB *ret = [self new];
    ret.connection = [DBConnectionPool openConnectionWithURL:URL error:err];
    if(!ret.connection)
        return nil;
    return ret;
}

// Returns a table whose name matches key
- (id)objectForKeyedSubscript:(id)key
{
    NSParameterAssert([key isKindOfClass:[NSString class]]);
    return [DBTable withDatabase:self name:key];
}

- (BOOL)createTable:(NSString *)tableName
        withColumns:(NSDictionary *)cols
         primaryKey:(NSDictionary *)primaryKeyInfo
            options:(DBTableCreationOptions)options
              error:(NSError **)err
{
    NSMutableString *query  = [NSMutableString stringWithString:@"CREATE TABLE"];
    if(options & DBTableCreationOptionUnlessExists)
        [query appendString:@" IF NOT EXISTS"];
    [query appendFormat:@" %@(", tableName];
    
    NSMutableArray *colStrings = [NSMutableArray arrayWithCapacity:[cols count]];
    for(NSString *colName in cols) {
        id col = cols[colName];
        NSParameterAssert([col isKindOfClass:[NSDictionary class]]
                          || [col isKindOfClass:[NSString class]]);

        NSMutableString *colStr = [NSMutableString stringWithFormat:@"%@ %@",
                                   colName,
                                   [col isKindOfClass:[NSString class]] ? col : col[@"type"]];

        if(![col isKindOfClass:[NSString class]]) {
            if([col[@"unique"] boolValue])
                [colStr appendString:@" UNIQUE"];
            if([col[@"notnull"] boolValue])
                [colStr appendString:@" NOT NULL"];
            if(col[@"default"])
                [colStr appendFormat:@" DEFAULT '%@'", col[@"default"]];
        }
        [colStrings addObject:colStr];
    }
    [query appendString:[colStrings componentsJoinedByString:@", "]];

    if(primaryKeyInfo) {
        NSParameterAssert([primaryKeyInfo isKindOfClass:[NSDictionary class]]
                          || [primaryKeyInfo isKindOfClass:[NSString class]]);
        
        if([primaryKeyInfo isKindOfClass:[NSString class]])
            [query appendFormat:@", PRIMARY KEY(%@ DESC AUTOINCREMENT)", primaryKeyInfo];
        else
            [query appendFormat:@", PRIMARY KEY(%@ %@ %@)",
                primaryKeyInfo[@"column"],
                primaryKeyInfo[@"order"] ?: @"DESC",
                primaryKeyInfo[@"noautoincrement"] ? @"" : @" AUTOINCREMENT"];
    }
    [query appendString:@")"];

    [_connection executeSQL:query
              substitutions:nil
                      error:err];
    return err == nil;
}
@end
