#import "DBAlterTableQuery.h"
#import "DBQuery+Private.h"
#import "DBTable.h"

@implementation DBAlterTableQuery

- (instancetype)rename:(NSString *)name
{
    DBAlterTableQuery *ret = [self copy];
    ret->_nameToRenameTo   = name;
    return ret;
}
- (instancetype)appendColumns:(NSArray *)columns
{
    DBAlterTableQuery *ret = [self copy];
    ret->_columnsToAppend  = columns;
    return ret;
}

- (BOOL)_generateString:(NSMutableString *)q parameters:(NSMutableArray *)p
{
    NSParameterAssert(q && p);
    if(!self.table)
        return NO;

    if(_columnsToAppend.count == 0 && !_nameToRenameTo)
        return NO;

    [q appendString:@"ALTER TABLE `"];
    [q appendString:self.table.name];
    [q appendString:@"`"];

    if(_nameToRenameTo) {
        [q appendString:@" RENAME TO `"];
        [q appendString:_nameToRenameTo];
        [q appendString:@"`"];
    }

    for(NSUInteger i = 0; i < _columnsToAppend.count; ++i) {
        if(i > 0)
            [q appendString:@", "];
        [q appendString:@" ADD COLUMN "];
        [q appendString:[_columnsToAppend[i] sqlRepresentationForQuery:self withParameters:p]];
    }

    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    DBAlterTableQuery *copy = [super copyWithZone:zone];
    copy->_nameToRenameTo   = _nameToRenameTo;
    copy->_columnsToAppend  = _columnsToAppend;
    return copy;
}

@end
