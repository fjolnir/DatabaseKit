#import <DatabaseKit/DBTable.h>
#import <DatabaseKit/DBSQLRepresentable.h>

typedef NS_ENUM(NSUInteger, DBForeignKeyAction) {
    DBForeignKeyActionNone,
    DBForeignKeyActionRestrict,
    DBForeignKeyActionCascade,
    DBForeignKeyActionSetNull,
    DBForeignKeyActionSetDefault
};

typedef NS_ENUM(NSUInteger, DBConflictAction) {
    DBConflictActionNone,
    DBConflictActionRollback,
    DBConflictActionAbort,
    DBConflictActionFail,
    DBConflictActionIgnore,
    DBConflictActionReplace,
};

@interface DBColumn : NSObject <DBSQLRepresentable>
@property(readonly, nonatomic) NSString *name;
@property(readonly, nonatomic) NSString *type;
@property(readonly, nonatomic) NSArray *constraints;

+ (instancetype)columnWithName:(NSString *)name type:(NSString *)type constraints:(NSArray *)constraints;
@end

@interface DBConstraint : NSObject <DBSQLRepresentable>
@end

@interface DBNotNullConstraint : DBConstraint
@end

@interface DBUniqueConstraint : DBConstraint
@end

@interface DBPrimaryKeyConstraint : DBConstraint
@property(readonly, nonatomic) DBOrder order;
@property(readonly, nonatomic) BOOL autoIncrement;
@property(readonly, nonatomic) DBConflictAction conflictAction;

+ (instancetype)primaryKeyConstraintWithOrder:(DBOrder)order
                                autoIncrement:(BOOL)autoIncrement
                                   onConflict:(DBConflictAction)onConflict;
@end

@interface DBForeignKeyConstraint : DBConstraint
@property(readonly, nonatomic) NSString *tableName;
@property(readonly, nonatomic) NSString *columnName;
@property(readonly, nonatomic) DBForeignKeyAction deleteAction, updateAction;

+ (instancetype)foreignKeyConstraintWithTable:(NSString *)tableName
                                   columnName:(NSString *)columnName
                                     onDelete:(DBForeignKeyAction)onDelete
                                     onUpdate:(DBForeignKeyAction)onUpdate;
@end

@interface DBDefaultConstraint : DBConstraint
@property(readonly, nonatomic) id value;

+ (instancetype)defaultConstraintWithValue:(id)value;
@end