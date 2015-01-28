#import "DBColumnDefinition.h"
#import "DB.h"
#import "DBConnection.h"
#import "DBQuery.h"
#import "DBUtilities.h"

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
        [sql appendString:[sortedConstraints[i] sqlRepresentationForQuery:query withParameters:parameters]];
    }
    return sql;
}

- (NSUInteger)hash
{
    return [_name hash];
}

- (BOOL)isEqual:(id)object
{
    if([object isKindOfClass:self.class])
        return [_name isEqual:[object name]];
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
    if(_deferred)
        [sql appendString:@" DEFERRABLE INITIALLY DEFERRED"];
    return sql;
}
@end

@implementation DBDefaultConstraint
+ (instancetype)defaultConstraintWithValue:(id)value
{
    NSParameterAssert([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]);

    DBDefaultConstraint *constr = [self new];
    constr->_value = value;
    return constr;
}
- (NSString *)sqlRepresentationForQuery:(DBQuery *)query withParameters:(NSMutableArray *)parameters;
{
    NSMutableString *str = [@"DEFAULT " mutableCopy];
    if([_value isKindOfClass:[NSString class]])
        [str appendFormat:@"'%@'", _value];
    else
        [str appendFormat:@"%@", _value];
    return str;
}
@end
