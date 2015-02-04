#import "DBColumnDefinition.h"
#import "DB.h"
#import "DBConnection.h"
#import "DBQuery.h"
#import "DBUtilities.h"
#import "NSString+DBAdditions.h"
#import "NSCollections+DBAdditions.h"

@implementation DBColumnDefinition
+ (instancetype)columnWithName:(NSString *)name type:(DBType)type constraints:(NSArray *)constraints
{
    NSParameterAssert(name);
    
    DBColumnDefinition *col = [self new];
    col->_name        = name;
    col->_type        = type;
    col->_constraints = constraints;
    return col;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if((self = [self init])) {
        _name = [aDecoder decodeObjectForKey:@"name"];
        _type = [aDecoder decodeIntegerForKey:@"type"];
        _constraints = [aDecoder decodeObjectForKey:@"constraints"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeInteger:_type forKey:@"type"];
    [aCoder encodeObject:_constraints forKey:@"constraints"];
}

- (NSString *)sqlRepresentationForQuery:(DBQuery *)query withParameters:(NSMutableArray *)parameters
{
    NSMutableString *sql = [@"`" mutableCopy];
    [sql appendString:[_name mutableCopy]];
    [sql appendString:@"` "];
    [sql appendString:[[query.database.connection class] ?: [DBConnection class] sqlForType:_type]];
    [sql appendString:@" "];

    NSArray *sortedConstraints = [_constraints sortedArrayUsingComparator:^(DBConstraint *a, DBConstraint *b) {
        return [@([[a class] priority]) compare:@([[b class] priority])];
    }];
    for(NSUInteger i = 0; i < sortedConstraints.count; ++i) {
        if(i > 0)
            [sql appendString:@" "];
        [sql appendString:[sortedConstraints[i] columnConstraintSQLRepresentation]];
    }
    return sql;
}

- (NSUInteger)hash
{
    return [_name hash] + _type;
}

- (BOOL)isEqual:(id)object
{
    if([object isKindOfClass:self.class])
        return DBEqual(_name, [object name])
            && _type == [(DBColumnDefinition *)object type]
            && DBEqual(_constraints, [object constraints]);
    else
        return NO;
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

- (BOOL)addToColumn:(NSString *)column inTable:(DBTable *)table error:(NSError **)outErr
{
    DBNotImplemented();
    return NO;
}

- (NSUInteger)hash
{
    return self.class.hash;
}
- (BOOL)isEqual:(id)object
{
    return [object class] == self.class;
}
@end

@implementation DBNotNullConstraint
- (NSString *)columnConstraintSQLRepresentation
{
    return @"NOT NULL";
}
@end

@implementation DBUniqueConstraint
+ (instancetype)uniqueConstraintWithColumnNames:(NSArray *)columns
{
    DBUniqueConstraint * const constr = [self new];
    constr->_columnNames = columns;
    return constr;
}
+ (NSUInteger)priority
{
    return 2;
}
- (NSString *)columnConstraintSQLRepresentation;
{
    return @"UNIQUE";
}
- (NSString *)tableConstraintSQLRepresentation
{
    NSAssert(_columnNames.count > 0, @"UNIQUE constraints on tables must specify columns");
    return [NSString stringWithFormat:@"UNIQUE(`%@`)",
            [[_columnNames db_map:^(NSString *columnName) {
                return columnName;
            }] componentsJoinedByString:@"`, `"]];
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

- (NSString *)columnConstraintSQLRepresentation;
{
    NSMutableString *sql = [NSMutableString stringWithString:@"PRIMARY KEY"];
    switch(_order) {
        case DBOrderAscending:
            [sql appendString:@" ASC"];
            break;
        case DBOrderDescending:
            [sql appendString:@" DESC"];
            break;
        default:
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
                                     deferred:(BOOL)deferred
                                     onDelete:(DBForeignKeyAction)onDelete
                                     onUpdate:(DBForeignKeyAction)onUpdate
{
    NSParameterAssert(tableName && columnName);

    DBForeignKeyConstraint *constr = [self new];
    constr->_tableName    = tableName;
    constr->_columnName   = columnName;
    constr->_deferred     = deferred;
    constr->_deleteAction = onDelete;
    constr->_updateAction = onUpdate;
    return constr;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if((self = [self init])) {
        _tableName    = [aDecoder decodeObjectForKey:@"tableName"];
        _columnName   = [aDecoder decodeObjectForKey:@"columnName"];
        _deferred     = [aDecoder decodeBoolForKey:@"deferred"];
        _deleteAction = [aDecoder decodeIntegerForKey:@"deleteAction"];
        _updateAction = [aDecoder decodeIntegerForKey:@"updateAction"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_tableName forKey:@"tableName"];
    [aCoder encodeObject:_columnName forKey:@"columnName"];
    [aCoder encodeBool:_deferred forKey:@"deferred"];
    [aCoder encodeInteger:_deleteAction forKey:@"deleteAction"];
    [aCoder encodeInteger:_updateAction forKey:@"updateAction"];
}

+ (NSUInteger)priority
{
    return 1;
}

- (NSString *)columnConstraintSQLRepresentation
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
    if(_deferred)
        [sql appendString:@" DEFERRABLE INITIALLY DEFERRED"];
    return sql;
}

- (NSUInteger)hash
{
    return _tableName.hash ^ _columnName.hash;
}
- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:self.class]
        && DBEqual([object tableName], _tableName)
        && DBEqual([object columnName], _columnName)
        && [object deferred] == _deferred
        && [object updateAction] == _updateAction
        && [object deleteAction] == _deleteAction;
}
@end

@implementation DBDefaultConstraint
+ (instancetype)defaultConstraintWithValue:(id<NSObject, NSCoding>)value
{
    NSParameterAssert([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]);

    DBDefaultConstraint *constr = [self new];
    constr->_value = value;
    return constr;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if((self = [self init])) {
        _value = [aDecoder decodeObjectForKey:@"value"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_value forKey:@"value"];
}

- (NSString *)columnConstraintSQLRepresentation;
{
    NSMutableString *str = [@"DEFAULT " mutableCopy];
    if([_value isKindOfClass:[NSString class]])
        [str appendFormat:@"'%@'", _value];
    else
        [str appendFormat:@"%@", _value];
    return str;
}

- (NSUInteger)hash
{
    return [_value hash];
}
- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:self.class]
        && DBEqual([object value], _value);
}
@end
