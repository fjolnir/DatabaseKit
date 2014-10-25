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

- (NSString *)sqlRepresentationForQuery:(DBQuery *)query withParameters:(NSMutableArray *)parameters
{
    NSMutableString *sql = [_name mutableCopy];
    [sql appendString:@" "];
    [sql appendString:_type];
    [sql appendString:@" "];

    NSSortDescriptor *prioritySort = [NSSortDescriptor sortDescriptorWithKey:@"_priority" ascending:NO];
    for(DBConstraint *constr in [_constraints sortedArrayUsingDescriptors:@[prioritySort]]) {
        [sql appendString:[constr sqlRepresentationForQuery:query withParameters:parameters]];
    }
    return sql;
}
@end

@implementation DBConstraint : NSObject
+ (NSUInteger)_priority
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
+ (NSUInteger)_priority
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

+ (NSUInteger)_priority
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
