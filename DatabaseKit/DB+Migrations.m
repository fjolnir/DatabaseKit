#import "DB+Migrations.h"
#import "DBModel+Relationships.h"
#import "DBTable.h"
#import "DBQuery.h"
#import "NSString+DBAdditions.h"
#import <objc/runtime.h>

static NSString * const kCYMigrationTableName = @"DBKitSchemaInfo";
@implementation DB (Migrations)

- (NSDictionary *)tableCreationQueriesForClasses:(NSArray *)classes
{
    NSMutableDictionary *creates = [NSMutableDictionary dictionaryWithCapacity:[classes count]];
    for(Class klass in classes) {
        NSMutableArray *columns = [NSMutableArray arrayWithObject:
                                   [DBColumnDefinition columnWithName:@"identifier"
                                                       type:DBTypeText
                                                constraints:@[[DBPrimaryKeyConstraint
                                                               primaryKeyConstraintWithOrder:DBOrderAscending
                                                               autoIncrement:NO
                                                               onConflict:DBConflictActionFail]]]];
        for(NSString *key in [klass savedKeys]) {
            DBType type = DBTypeUnknown;
            Class keyClass = nil;
            char enc = [klass typeForKey:key class:&keyClass];
            if(enc == _C_ID)
                type = [[self.connection class] typeForClass:keyClass];
            else
                type = [[self.connection class] typeForObjCScalarEncoding:enc];
            if(!type) {
                if([keyClass isSubclassOfClass:[NSSet class]]) { // To many
                    Class counterpart = [klass relatedClassForKey:key];
                    if(counterpart && ![creates[[counterpart tableName]] hasColumnNamed:[klass foreignKeyName]]) {
                        DBColumnDefinition *foreignKeyCol = [DBColumnDefinition
                                                   columnWithName:[klass foreignKeyName]
                                                   type:DBTypeText
                                                   constraints:@[[DBForeignKeyConstraint
                                                                  foreignKeyConstraintWithTable:[klass tableName]
                                                                  columnName:@"identifier"
                                                                  onDelete:DBForeignKeyActionCascade
                                                                  onUpdate:DBForeignKeyActionCascade]]];
                        if(!creates[[counterpart tableName]])
                            creates[[counterpart tableName]] = [[[self create] table:[counterpart tableName]] columns:@[foreignKeyCol]];
                        else {
                            DBCreateQuery *q = creates[[klass tableName]];
                            creates[[counterpart tableName]] = [q columns:[q.columns arrayByAddingObject:foreignKeyCol]];
                        }
                    }
                } else if([keyClass isSubclassOfClass:[DBModel class]]) { // To one
                    Class counterpart = [klass relatedClassForKey:key];
                    if(counterpart && ![creates[[klass tableName]] hasColumnNamed:[counterpart foreignKeyName]]) {
                        DBColumnDefinition *foreignKeyCol = [DBColumnDefinition
                                                   columnWithName:[counterpart foreignKeyName]
                                                   type:@"TEXT"
                                                   constraints:@[[DBForeignKeyConstraint
                                                                  foreignKeyConstraintWithTable:[counterpart tableName]
                                                                  columnName:@"identifier"
                                                                  onDelete:DBForeignKeyActionCascade
                                                                  onUpdate:DBForeignKeyActionCascade]]];
                        if(!creates[[klass tableName]])
                            creates[[counterpart tableName]] = [[[self create] table:[counterpart tableName]] columns:@[foreignKeyCol]];
                        else {
                            DBCreateQuery *q = creates[[klass tableName]];
                            creates[[klass tableName]] = [q columns:[q.columns arrayByAddingObject:foreignKeyCol]];
                        }
                    }
                }
                continue;
            }

            NSAssert(NSNotFound == [columns indexOfObjectPassingTest:^(DBColumnDefinition *col, NSUInteger _, BOOL *__) {
                return [col.name isEqualToString:key];
            }], @"Duplicate column %@", key);
            [columns addObject:[DBColumnDefinition columnWithName:key
                                                   type:type
                                            constraints:[klass constraintsForKey:key]]];
        }
        if(!creates[[klass tableName]])
            creates[[klass tableName]] = [[[self create] table:[klass tableName]] columns:columns];
        else {
            DBCreateQuery *q = creates[[klass tableName]];
            creates[[klass tableName]] = [q columns:[q.columns arrayByAddingObjectsFromArray:columns]];
        }
    }
    return creates;
}

- (BOOL)migrateModelClasses:(NSArray *)classes error:(NSError **)outErr
{
    return [self.connection transaction:^{
        NSMutableDictionary *creates = [[self tableCreationQueriesForClasses:classes] mutableCopy];
        for(Class klass in classes) {
            NSString *tableName = [klass tableName];
            DBCreateQuery *createQuery = creates[tableName];
            NSDictionary *lastMigration = [self currentMigrationForModelClass:klass error:outErr];
            if(lastMigration) {
                NSSet *currentColumns = [NSKeyedUnarchiver unarchiveObjectWithData:lastMigration[@"columns"]];
                NSSet *untouchedColumns = [currentColumns
                                                   filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(DBColumnDefinition *col, NSDictionary *bindings) {
                    return [[creates[tableName] columns] containsObject:col];
                }]];

                if(![currentColumns isEqual:untouchedColumns]) {
                    if(![self.connection executeSQL:@"PRAGMA foreign_keys = OFF" substitutions:nil error:outErr])
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

                    if(![self.connection executeSQL:@"PRAGMA foreign_keys = ON" substitutions:nil error:outErr])
                        return DBTransactionRollBack;
                }
            } else {
                if(![(DBCreateQuery *)creates[tableName] execute:outErr])
                    return DBTransactionRollBack;
            }

            DBInsertQuery *migration = [[[self migrationTable]
             insert:@{
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
        DBCreateQuery *migrationCreate = [[[self create] table:kCYMigrationTableName] columns:@[
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
//
//- (BOOL)migrateInDatabase:(DB *)db error:(NSError **)outErr
//{
//    return [db.connection transaction:^{
//        NSDictionary *lastMigration = [self currentMigrationForModelClass:klass error:outErr];
//        if(!lastMigration)
//            return DBTransactionRollBack;
//
//        NSDictionary *existingCols = [db.connection columnsForTable:[self tableName]];
//        NSLog(@"%@", existingCols);
//        if([existingCols count] > 0) {
//            // TODO
////            NSUInteger version = [lastMigration[@"version"] unsignedIntegerValue];
//            return DBTransactionRollBack;
//        } else {
//                if(![self createTableInDatabase:db error:outErr])
//                    return DBTransactionRollBack;
//                if(![[db[@"_DBKitSchemaInfo"] insert:@{ @"table": [self tableName], @"version": @0 }] execute:outErr])
//                   return DBTransactionRollBack;
//               return DBTransactionCommit;
//        }
//    }];
//}
//
//- (BOOL)createTableInDatabase:(DB *)db error:(NSError **)outErr
//{
//    NSParameterAssert([[db.connection columnsForTable:[self tableName]] count] == 0);
//
//    NSMutableArray *cols = [NSMutableArray arrayWithObject:@"identifier TEXT PRIMARY KEY ASC"];
//    for(NSString *key in [self savedKeys]) {
//        DBConstraints constr = [self constraintsForKey:key];
//        NSString *type = [self _sqlTypeForKey:key connection:db.connection];
//        if(!type) continue;
//
//        [cols addObject:[NSString stringWithFormat:
//                         @"%@ %@%@%@", key, type,
//                         (constr & DBUniqueConstraint) ? @" UNIQUE" : @"",
//                         (constr & DBNotNullConstraint) ? @" NOT NULL" : @""]];
//    }
//    NSMutableString *query = [NSMutableString stringWithFormat:@"CREATE TABLE %@(%@)", [self tableName], [cols componentsJoinedByString:@", "]];
//    return [db.connection executeSQL:query substitutions:nil error:outErr];
//}

@end
