#import "DB+Migrations.h"
#import "DBModel+Private.h"
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

static NSString * const kDBMigrationTableName = @"DBKitSchemaInfo";

@implementation DB (Migrations)

- (NSArray *)tableCreationQueriesForClass:(Class)klass
{
    NSMutableArray *queries = [NSMutableArray new];

    NSMutableArray *columns = [NSMutableArray new];
    for(NSString *key in [klass savedKeys]) {
        DBType type = DBTypeUnknown;
        DBPropertyAttributes *keyAttrs = DBAttributesForProperty(klass, class_getProperty(klass, key.UTF8String));
        if(keyAttrs->encoding[0] == _C_ID) {
            BOOL pluralRelationship;
            Class relatedKlass;
            if([klass _attributeIsRelationship:keyAttrs isPlural:&pluralRelationship relatedClass:&relatedKlass]) {
                [queries addObject:[[[self create]
                                    table:[klass joinTableNameForKey:key]]
                                    columns:@[
                    [DBColumnDefinition columnWithName:[[klass tableName] db_singularizedString]
                                                  type:DBTypeText
                                           constraints:@[[DBForeignKeyConstraint
                                                          foreignKeyConstraintWithTable:[klass tableName]
                                                          columnName:kDBUUIDKey
                                                          deferred:YES
                                                          onDelete:DBForeignKeyActionCascade
                                                          onUpdate:DBForeignKeyActionCascade],
                                                         [DBNotNullConstraint new]]],
                    [DBColumnDefinition columnWithName:key
                                                  type:DBTypeText
                                           constraints:@[[DBForeignKeyConstraint
                                                          foreignKeyConstraintWithTable:[relatedKlass tableName]
                                                          columnName:kDBUUIDKey
                                                          deferred:YES
                                                          onDelete:DBForeignKeyActionCascade
                                                          onUpdate:DBForeignKeyActionCascade],
                                                         [DBNotNullConstraint new]]]
                ]]];
                continue;
            } else
                type = [[self.connection class] typeForClass:keyAttrs->klass];
        } else
            type = [[self.connection class] typeForObjCScalarEncoding:keyAttrs->encoding[0]];
        free(keyAttrs);

        [columns addObject:[DBColumnDefinition columnWithName:key
                                                         type:type
                                                  constraints:[klass constraintsForKey:key]]];
    }
    [queries addObject:[[[self create] table:[klass tableName]] columns:columns]];
    return queries;
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
        for(Class klass in classes) {
            NSArray *queries = [self tableCreationQueriesForClass:klass];
            for(DBCreateTableQuery *query in queries) {
                NSDictionary *lastMigration = [self currentMigrationForTable:query.tableName error:outErr];
                if(lastMigration) {
                    NSSet *currentColumns   = [NSKeyedUnarchiver unarchiveObjectWithData:lastMigration[@"columns"]];
                    NSSet *untouchedColumns = [currentColumns db_filter:^(DBColumnDefinition *col) {
                        return [query.columns containsObject:col];
                    }];

                    if(![currentColumns isEqual:untouchedColumns]) {
                        if([[self.connection execute:@"PRAGMA foreign_keys = OFF" substitutions:nil error:outErr] step:outErr] != DBResultStateAtEnd)
                            return DBTransactionRollBack;

                        // Create the new table using a temporary name
                        NSString *tempTableName = [@"_DBKitMigration_tmp_" stringByAppendingString:query.tableName];
                        if(![[query table:tempTableName] execute:outErr])
                            return DBTransactionRollBack;

                        // Copy over the existing data
                        DBSelectQuery *sourceQuery = [self[query.tableName] select:[[untouchedColumns valueForKey:@"name"] allObjects]];
                        if(![[self[tempTableName] insertUsingSelect:sourceQuery] execute:outErr])
                            return DBTransactionRollBack;

                        // Drop old, and rename new
                        if(![[self[query.tableName] drop] execute:outErr])
                            return DBTransactionRollBack;
                        if(![[[self[tempTableName] alter] rename:query.tableName] execute:outErr])
                            return DBTransactionRollBack;

                        if([[self.connection execute:@"PRAGMA foreign_keys = ON" substitutions:nil error:outErr] step:outErr] != DBResultStateAtEnd)
                            return DBTransactionRollBack;
                    }
                } else {
                    if(![query execute:outErr])
                        return DBTransactionRollBack;
                }

                DBInsertQuery *migration = [[self.migrationTable insert:@{
                     @"table":   query.tableName,
                     @"columns": [NSKeyedArchiver archivedDataWithRootObject:[NSSet setWithArray:query.columns]]
                 }] or:DBInsertFallbackReplace];
                if(![migration execute:outErr])
                    return DBTransactionRollBack;
            }

            for(DBIndex *idx in [klass indices]) {
                if(![idx addToTable:self[[klass tableName]] error:outErr])
                    return DBTransactionRollBack;
            }
        }
        return DBTransactionCommit;
    }];
}

- (DBTable *)migrationTable
{
    if(![self.connection tableExists:kDBMigrationTableName]) {
        DBCreateTableQuery *migrationCreate = [[[self create] table:kDBMigrationTableName] columns:@[
            [DBColumnDefinition columnWithName:@"table"   type:DBTypeText constraints:@[[DBNotNullConstraint new], [DBUniqueConstraint new]]],
            [DBColumnDefinition columnWithName:@"columns" type:DBTypeBlob constraints:@[[DBNotNullConstraint new]]]
        ]];
        NSError *err;
        if(![migrationCreate execute:&err])
            return nil;
    }
    return self[kDBMigrationTableName];
}

- (NSDictionary *)currentMigrationForTable:(NSString *)tableName error:(NSError **)outErr
{
    return [[[self.migrationTable select] where:@"table=%@", tableName] firstObject];
}

@end
