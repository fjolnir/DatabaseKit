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

#pragma mark - Constraints
@protocol DBColumnConstraint <NSObject>
- (NSString *)columnConstraintSQLRepresentation;
@end
@protocol DBTableConstraint <NSObject>
- (NSString *)tableConstraintSQLRepresentation;
@end

@interface DBConstraint : NSObject <NSCoding>
+ (NSUInteger)priority;
@end

@interface DBNotNullConstraint : DBConstraint <DBColumnConstraint>
@end

@interface DBUniqueConstraint : DBConstraint <DBColumnConstraint, DBTableConstraint>
@property(readonly) NSArray *columnNames;
+ (instancetype)uniqueConstraintWithColumnNames:(NSArray *)columns;
@end

@interface DBPrimaryKeyConstraint : DBConstraint <DBColumnConstraint>
@property(readonly) DBOrder order;
@property(readonly) BOOL autoIncrement;
@property(readonly) DBConflictAction conflictAction;

+ (instancetype)primaryKeyConstraintWithOrder:(DBOrder)order
                                autoIncrement:(BOOL)autoIncrement
                                   onConflict:(DBConflictAction)onConflict;
@end

@interface DBForeignKeyConstraint : DBConstraint <DBColumnConstraint>
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

@interface DBDefaultConstraint : DBConstraint <DBColumnConstraint>
@property(readonly) id value;

+ (instancetype)defaultConstraintWithValue:(id<NSObject, NSCoding>)value;
@end
