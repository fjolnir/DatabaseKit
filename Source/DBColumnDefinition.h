#import <Foundation/Foundation.h>
#import <DatabaseKit/DBConnection.h>
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

@interface DBColumnDefinition : NSObject <DBSQLRepresentable, NSCoding>
@property(readonly) NSString *name;
@property(readonly) DBType type;
@property(readonly) NSArray *constraints;

+ (instancetype)columnWithName:(NSString *)name type:(DBType)type constraints:(NSArray *)constraints;
@end

@interface DBConstraint : NSObject <DBSQLRepresentable, NSCoding>
+ (NSUInteger)priority;
@end

@interface DBNotNullConstraint : DBConstraint
@end

@interface DBUniqueConstraint : DBConstraint
@end

@interface DBPrimaryKeyConstraint : DBConstraint
@property(readonly) DBOrder order;
@property(readonly) BOOL autoIncrement;
@property(readonly) DBConflictAction conflictAction;

+ (instancetype)primaryKeyConstraintWithOrder:(DBOrder)order
                                autoIncrement:(BOOL)autoIncrement
                                   onConflict:(DBConflictAction)onConflict;
@end

@interface DBForeignKeyConstraint : DBConstraint
@property(readonly) NSString *tableName;
@property(readonly) NSString *columnName;
@property(readonly) BOOL deferred;
@property(readonly) DBForeignKeyAction deleteAction, updateAction;

+ (instancetype)foreignKeyConstraintWithTable:(NSString *)tableName
                                   columnName:(NSString *)columnName
                                     deferred:(BOOL)deferred
                                     onDelete:(DBForeignKeyAction)onDelete
                                     onUpdate:(DBForeignKeyAction)onUpdate;
@end

@interface DBDefaultConstraint : DBConstraint
@property(readonly) id value;

+ (instancetype)defaultConstraintWithValue:(id)value;
@end
