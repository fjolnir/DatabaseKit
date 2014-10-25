#import "DB+Migrations.h"
#import "DBModel+Relationships.h"
#import "DBTable.h"
#import "DBQuery.h"
#import "NSString+DBAdditions.h"
#import <objc/runtime.h>

@implementation DB (Migrations)

- (BOOL)migrateModelClasses:(NSArray *)classes error:(NSError **)outErr
{
    return [self.connection transaction:^{
        NSMutableDictionary *creates = [NSMutableDictionary dictionaryWithCapacity:[classes count]];
        for(Class klass in classes) {
            NSDictionary *lastMigration = [self currentMigrationForModelClass:klass error:outErr];
            if(lastMigration) {
                // TODO
                return DBTransactionRollBack;
            } else {
                // Begin by adding all the simple columns (foreign keys handled later)
                NSMutableArray *columns = [NSMutableArray new];
                for(NSString *key in [klass savedKeys]) {
                    NSString *type = nil;
                    Class keyClass = nil;
                    char enc = [klass typeForKey:key class:&keyClass];
                    if(enc == _C_ID)
                        type = [[self.connection class] typeForClass:keyClass];
                    else
                        type = [[self.connection class] typeForObjCScalarEncoding:enc];
                    if(!type) {
                        if([keyClass isSubclassOfClass:[NSSet class]]) {
                            Class counterpart = [klass relatedClassForKey:key];
                            if(counterpart) {
                                DBColumn *foreignKeyCol = [DBColumn
                                                           columnWithName:[klass foreignKeyName]
                                                           type:@"TEXT"
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
                                }                            }
                        }
                        continue;
                    }

                    [columns addObject:[DBColumn columnWithName:key
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
        }
        for(NSString *tableName in creates) {
            if(![(DBCreateQuery *)creates[tableName] execute:outErr])
                return DBTransactionRollBack;
        }
        return DBTransactionCommit;
    }];
}

- (DBTable *)migrationTable
{
    if(![self.connection columnsForTable:@"_DBKitSchemaInfo"]) {
        DBCreateQuery *migrationCreate = [[[self create] table:@"_DBKitSchemaInfo"] columns:@[
            [DBColumn columnWithName:@"table" type:@"TEXT" constraints:@[[DBNotNullConstraint new]]]
        ]];
        if(![migrationCreate execute])
            return nil;
    }
    return self[@"_DBKitSchemaInfo"];
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
