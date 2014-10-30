#import "DBIndex.h"
#import "DBTable.h"

@implementation DBIndex

+ (instancetype)indexWithName:(NSString *)name onColumns:(NSArray *)columns unique:(BOOL)unique
{
    DBIndex *index = [self new];
    index->_name = name;
    index->_columns = columns;
    index->_unique = unique;
    return index;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if((self = [self init])) {
        _name = [aDecoder decodeObjectForKey:@"name"];
        _unique = [aDecoder decodeBoolForKey:@"unique"];
        _columns = [aDecoder decodeObjectForKey:@"columns"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeBool:_unique forKey:@"unique"];
    [aCoder encodeObject:_columns forKey:@"columns"];
}

- (BOOL)addToTable:(DBTable *)table error:(NSError **)outErr
{
    NSParameterAssert(table);

    NSMutableString *q = [NSMutableString stringWithString:@"CREATE "];
    if(_unique)
        [q appendString:@"UNIQUE "];
    [q appendString:@"INDEX IF NOT EXISTS `"];
    if([_name length] == 0)
        return NO;
    [q appendString:_name];
    [q appendString:@"` ON `"];
    [q appendString:table.name];
    [q appendString:@"` (`"];
    
    if([_columns count] == 0)
        return NO;
    [q appendString:[_columns componentsJoinedByString:@"`, `"]];
    [q appendString:@"`)"];

    return [[table.database.connection execute:q substitutions:nil error:outErr] step:NULL] == DBResultStateAtEnd;
}

@end
