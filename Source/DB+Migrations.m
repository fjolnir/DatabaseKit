#import "DB+Migrations.h"
#import "DBModel.h"
#import "DBTable.h"
#import "DBInsertQuery.h"
#import "DBSelectQuery.h"
#import "DBCreateTableQuery.h"
#import "DBAlterTableQuery.h"
#import "DBDropTableQuery.h"
#import "DBIndex.h"
#import "NSString+DBAdditions.h"
#import "NSCollections+DBAdditions.h"
#import "DBIntrospection.h"
#import <objc/runtime.h>

static NSString * const kCYMigrationTableName = @"DBKitSchemaInfo";

@implementation DB (Migrations)

- (NSDictionary *)tableCreationQueriesForClasses:(NSArray *)classes
{
    NSMutableDictionary *creates = [NSMutableDictionary dictionaryWithCapacity:[classes count]];
    for(Class klass in classes) {
        NSMutableArray *columns = [NSMutableArray new];
        for(NSString *key in [klass savedKeys]) {
            DBType type = DBTypeUnknown;
            DBPropertyAttributes *keyAttrs = DBAttributesForProperty(klass, class_getProperty(klass, key.UTF8String));
            if(keyAttrs->encoding[0] == _C_ID) {
                type = [[self.connection class] typeForClass:keyAttrs->klass];
                if(type == DBTypeUnknown && [keyAttrs->klass conformsToProtocol:@protocol(NSCoding)])
                    type = DBTypeBlob;
            } else
                type = [[self.connection class] typeForObjCScalarEncoding:keyAttrs->encoding[0]];
            free(keyAttrs);

            [columns addObject:[DBColumnDefinition columnWithName:key
                                                             type:type
                                                      constraints:[klass constraintsForKey:key]]];
        }
        if(!creates[[klass tableName]])
            creates[[klass tableName]] = [[[self create] table:[klass tableName]] columns:columns];
        else {
            DBCreateTableQuery *q = creates[[klass tableName]];
            creates[[klass tableName]] = [q columns:[q.columns arrayByAddingObjectsFromArray:columns]];
        }
    }
    return creates;
}

- (BOOL)migrateSchema:(NSError **)outErr
{
    NSArray *modelClasses = [DBClassesInheritingFrom([DBModel class])
                             filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"savedKeys.@count > 0"]];
    return [self migrateModelClasses:modelClasses error:outErr];
}

- (BOOL)migrateModelClasses:(NSArray *)classes error:(NSError **)outErr
{
    return [self.connection transaction:^{
        NSMutableDictionary *creates = [[self tableCreationQueriesForClasses:classes] mutableCopy];
        for(Class klass in classes) {
            NSString *tableName = [klass tableName];
            DBCreateTableQuery *createQuery = creates[tableName];
            NSDictionary *lastMigration = [self currentMigrationForModelClass:klass error:outErr];
            if(lastMigration) {
                NSSet *currentColumns   = [NSKeyedUnarchiver unarchiveObjectWithData:lastMigration[@"columns"]];
                NSSet *untouchedColumns = [currentColumns db_filter:^(DBColumnDefinition *col) {
                    return [[creates[tableName] columns] containsObject:col];
                }];

                if(![currentColumns isEqual:untouchedColumns]) {
                    if([[self.connection execute:@"PRAGMA foreign_keys = OFF" substitutions:nil error:outErr] step:outErr] != DBResultStateAtEnd)
                        return DBTransactionRollBack;

                    // Create the new table using a temporary name
                    NSString *tempTableName = [@"_DBKitMigration_tmp_" stringByAppendingString:tableName];
                    if(![[createQuery table:tempTableName] execute:outErr])
                        return DBTransactionRollBack;

                    // Copy over the existing data
                    DBSelectQuery *sourceQuery = [self[tableName] select:[[untouchedColumns valueForKey:@"name"] allObjects]];
                    if(![[self[tempTableName] insertUsingSelect:sourceQuery] execute:outErr])
                        return DBTransactionRollBack;

                    // Drop old, and rename new
                    if(![[self[tableName] drop] execute:outErr])
                        return DBTransactionRollBack;
                    if(![[[self[tempTableName] alter] rename:tableName] execute:outErr])
                        return DBTransactionRollBack;

                    if([[self.connection execute:@"PRAGMA foreign_keys = ON" substitutions:nil error:outErr] step:outErr] != DBResultStateAtEnd)
                        return DBTransactionRollBack;
                }
            } else {
                if(![(DBCreateTableQuery *)creates[tableName] execute:outErr])
                    return DBTransactionRollBack;
            }

            for(DBIndex *idx in [klass indices]) {
                if(![idx addToTable:self[tableName] error:outErr])
                    return DBTransactionRollBack;
            }

            DBInsertQuery *migration = [[self.migrationTable insert:@{
                 @"table": tableName,
                 @"columns": [NSKeyedArchiver archivedDataWithRootObject:[NSSet setWithArray:[creates[tableName] valueForKey:@"columns"]]]
             }] or:DBInsertFallbackReplace];
            if(![migration execute:outErr])
                return DBTransactionRollBack;
        }
        return DBTransactionCommit;
    }];
}

- (DBTable *)migrationTable
{
    if(![self.connection tableExists:kCYMigrationTableName]) {
        DBCreateTableQuery *migrationCreate = [[[self create] table:kCYMigrationTableName] columns:@[
            [DBColumnDefinition columnWithName:@"table" type:DBTypeText constraints:@[[DBNotNullConstraint new], [DBUniqueConstraint new]]],
            [DBColumnDefinition columnWithName:@"columns" type:DBTypeBlob constraints:@[[DBNotNullConstraint new]]]
        ]];
        NSError *err;
        if(![migrationCreate execute:&err])
            return nil;
    }
    return self[kCYMigrationTableName];
}

- (NSDictionary *)currentMigrationForModelClass:(Class)klass error:(NSError **)outErr
{
    NSParameterAssert(klass != [DBModel class] && [klass isSubclassOfClass:[DBModel class]]);
    return [[[[self migrationTable]  select] where:@"table=%@", [klass tableName]] firstObject];
}

@end
