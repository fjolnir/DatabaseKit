#import "DBColumn.h"

@implementation DBColumn
+ (instancetype)columnWithName:(NSString *)name type:(NSString *)type constraints:(NSArray *)constraints
{
    DBColumn *col = [self new];
    col->_name        = name;
    col->_type        = type;
    col->_constraints = constraints;
    return col;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if((self = [self init])) {
        _name = [aDecoder decodeObjectForKey:@"name"];
        _type = [aDecoder decodeObjectForKey:@"type"];
        _constraints = [aDecoder decodeObjectForKey:@"constraints"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_type forKey:@"type"];
    [aCoder encodeObject:_constraints forKey:@"constraints"];
}

- (NSString *)sqlRepresentationForQuery:(DBQuery *)query withParameters:(NSMutableArray *)parameters
{
    NSMutableString *sql = [@"`" mutableCopy];
    [sql appendString:[_name mutableCopy]];
    [sql appendString:@"` "];
    [sql appendString:_type];
    [sql appendString:@" "];

    NSArray *sortedConstraints = [_constraints sortedArrayUsingComparator:^(DBConstraint *a, DBConstraint *b) {
        return [@([[a class] priority]) compare:@([[b class] priority])];
    }];
    for(NSUInteger i = 0; i < [sortedConstraints count]; ++i) {
        if(i > 0)
            [sql appendString:@" "];
        [sql appendString:[sortedConstraints[i] sqlRepresentationForQuery:query withParameters:parameters]];
    }
    return sql;
}
@end

@implementation DBConstraint : NSObject
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return (self = [self init]);
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    // Nothing to encode
}

+ (NSUInteger)priority
{
    return 0;
}
- (NSString *)sqlRepresentationForQuery:(DBQuery *)query withParameters:(NSMutableArray *)parameters
{
    return nil;
}
@end

@implementation DBNotNullConstraint
- (NSString *)sqlRepresentationForQuery:(DBQuery *)query withParameters:(NSMutableArray *)parameters
{
    return @"NOT NULL";
}
@end

@implementation DBUniqueConstraint
+ (NSUInteger)priority
{
    return 2;
}
- (NSString *)sqlRepresentationForQuery:(DBQuery *)query withParameters:(NSMutableArray *)parameters;
{
    return @"UNIQUE";
}
@end

@implementation DBPrimaryKeyConstraint
+ (instancetype)primaryKeyConstraintWithOrder:(DBOrder)order
                                autoIncrement:(BOOL)autoIncrement
                                   onConflict:(DBConflictAction)onConflict
{
    DBPrimaryKeyConstraint *constr = [self new];
    constr->_order          = order;
    constr->_autoIncrement  = autoIncrement;
    constr->_conflictAction = onConflict;
    return constr;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if((self = [self init])) {
        _order = [aDecoder decodeIntegerForKey:@"order"];
        _autoIncrement  = [aDecoder decodeBoolForKey:@"autoIncrement"];
        _conflictAction = [aDecoder decodeIntegerForKey:@"conflictAction"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:_order forKey:@"order"];
    [aCoder encodeBool:_autoIncrement forKey:@"autoIncrement"];
    [aCoder encodeInteger:_conflictAction forKey:@"conflictAction"];
}

- (NSString *)sqlRepresentationForQuery:(DBQuery *)query withParameters:(NSMutableArray *)parameters;
{
    NSMutableString *sql = [NSMutableString stringWithString:@"PRIMARY KEY"];
    switch(_order) {
        case DBOrderAscending:
            [sql appendString:@" ASC"];
            break;
        case DBOrderDescending:
            [sql appendString:@" DESC"];
            break;
    }
    switch(_conflictAction) {
        case DBConflictActionRollback:
            [sql appendString:@" ON CONFLICT ROLLBACK"];
            break;
        case DBConflictActionAbort:
            [sql appendString:@" ON CONFLICT ABORT"];
            break;
        case DBConflictActionFail:
            [sql appendString:@" ON CONFLICT FAIL"];
            break;
        case DBConflictActionIgnore:
            [sql appendString:@" ON CONFLICT IGNORE"];
            break;
        case DBConflictActionReplace:
            [sql appendString:@" ON CONFLICT SET REPLACE"];
            break;
        default:
            break;
    }
    if(_autoIncrement)
        [sql appendString:@" AUTOINCREMENT"];
    return sql;
}
@end

@implementation DBForeignKeyConstraint
+ (instancetype)foreignKeyConstraintWithTable:(NSString *)tableName
                                   columnName:(NSString *)columnName
                                     onDelete:(DBForeignKeyAction)onDelete
                                     onUpdate:(DBForeignKeyAction)onUpdate
{
    DBForeignKeyConstraint *constr = [self new];
    constr->_tableName    = tableName;
    constr->_columnName   = columnName;
    constr->_deleteAction = onDelete;
    constr->_updateAction = onUpdate;
    return constr;
}

+ (NSUInteger)priority
{
    return 1;
}

- (NSString *)sqlRepresentationForQuery:(DBQuery *)query withParameters:(NSMutableArray *)parameters;
{
    NSMutableString *sql = [NSMutableString stringWithFormat:@"REFERENCES %@(%@)", _tableName, _columnName];
    switch(_deleteAction) {
        case DBForeignKeyActionRestrict:
            [sql appendString:@" ON DELETE RESTRICT_"];
            break;
        case DBForeignKeyActionCascade:
            [sql appendString:@" ON DELETE CASCADE"];
            break;
        case DBForeignKeyActionSetNull:
            [sql appendString:@" ON DELETE SET NULL"];
            break;
        case DBForeignKeyActionSetDefault:
            [sql appendString:@" ON DELETE SET DEFAULT"];
            break;
        default:
            break;
    }
    return sql;
}
@end

@implementation DBDefaultConstraint
+ (instancetype)defaultConstraintWithValue:(id)value
{
    DBDefaultConstraint *constr = [self new];
    constr->_value = value;
    return constr;
}
- (NSString *)sqlRepresentationForQuery:(DBQuery *)query withParameters:(NSMutableArray *)parameters;
{
    [parameters addObject:_value];
    return @"DEFAULT $1";
}
@end
