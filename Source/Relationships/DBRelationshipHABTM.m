//
//  DBRelationshipHABTM.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 9/12/07.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import "DBRelationshipHABTM.h"
#import "DBModel.h"
#import "DBTable.h"
#import "DBQuery.h"
#import "DBTable.h"
#import "DBModelPrivate.h"
#import "NSString+DBAdditions.h"

@implementation DBRelationshipHABTM
- (BOOL)respondsToKey:(NSString *)key supportsAdding:(BOOL *)supportsAddingRet
{

    if([key isEqualToString:self.name])
    {
        if(supportsAddingRet != NULL)
            *supportsAddingRet = NO;
        return YES;
    }
    else if([key isEqualToString:[self.name singularizedString]])
    {
        if(supportsAddingRet != NULL)
            *supportsAddingRet = YES;
        return YES;
    }
    return NO;
}


- (id)retrieveRecordForKey:(NSString *)key
                    filter:(id)conditions
                     order:(NSString *)order
                        by:(id)orderByFields
                     limit:(NSNumber *)limit
{
    if(![self respondsToKey:key])
        return nil;
    NSString *classPrefix = [[self.record class] classPrefix];
    NSString *partnerClassName = [classPrefix stringByAppendingString:[[key singularizedString] stringByCapitalizingFirstLetter]];
    Class partnerClass = NSClassFromString(partnerClassName);
    if(!partnerClass)
    {
        [NSException raise:@"DBKit error" format:@"No model class found for key %@! (looked for class named %@)",
                                                 key, partnerClassName];
        return nil;
    }

    NSString *joinTableName = [[self.record class] joinTableNameForModel:[self.record class] and:partnerClass];
    NSString *partnerIdCol  = [[self.record class] idColumnForModel:partnerClass];
    DBTable *partnerTable   = self.record.table.database[[partnerClass tableName]];

    DBQuery *q = [partnerTable select:partnerIdCol];
    q          = [q innerJoin:joinTableName on:@{ @"id": partnerIdCol }];
    q          = [q where:@{ [[self.record class] idColumn]: @(self.record.databaseId) }];
    if(conditions)
        q = [q where:conditions];
    if(order || orderByFields)
        q = [q order:order ? order : DBOrderAscending by:orderByFields];
    if(limit)
        q = [q limit:limit];

    NSMutableArray *partners = [NSMutableArray array];
    for(NSDictionary *row in [q execute]) {
        [partners addObject:[[partnerClass alloc] initWithTable:partnerTable
                                                             id:[row[partnerIdCol] unsignedIntValue]]];
    }
    return partners;
}

- (void)sendRecord:(id)aRecord forKey:(NSString *)key
{
    if(![self respondsToKey:key])
        return;

    // aRecord is an array
    Class partnerClass = [aRecord[0] class];
    NSString *joinTableName = [[self class] joinTableNameForModel:[self.record class] and:partnerClass];
    NSString *selfIdCol     = [[self.record class] idColumn];
    NSString *partnerIdCol  = [[self.record class] idColumnForModel:partnerClass];
    DBTable *joinTable = self.record.table.database[joinTableName];

    // First empty out the join table
    [[[joinTable delete] where:@{ [[self.record class] idColumn]: @(self.record.databaseId) }] execute];
    if(!aRecord)
        return;
    // Then populate it if any records where passed
    for(DBModel *partner in aRecord) {
        [[joinTable insert:@{ selfIdCol: @(self.record.databaseId), partnerIdCol: @(partner.databaseId)}] execute];
    }

}
- (void)addRecord:(id)aRecord forKey:(NSString *)key
{
    BOOL supportsAdding;
    if(![self respondsToKey:key supportsAdding:&supportsAdding] || !supportsAdding)
        return;

    // Check if the relationship already exists between us, if it does we shouldn't duplicate it
    // Note to self: maybe we should replace this with a query, it'd be faster but uglier code.
    NSArray *existingPartners = [self.record valueForKey:key];
    for(id existingPartner in existingPartners) {
        if([existingPartner databaseId] == [aRecord databaseId])
            return;
    }
    Class partnerClass = [aRecord class];
    NSString *joinTableName = [[self.record class] joinTableNameForModel:[self.record class] and:partnerClass];
    NSString *selfIdCol     = [[self.record class] idColumn];
    NSString *partnerIdCol  = [[self.record class] idColumnForModel:partnerClass];
    DBTable *joinTable      = self.record.table.database[joinTableName];

    [[joinTable insert:@{ selfIdCol: @(self.record.databaseId), partnerIdCol: @([aRecord databaseId])}] execute];
    if([DBModel enableCache])
        [[self.record readCache] removeObjectForKey:[key pluralizedString]];
}

- (void)removeRecord:(id)aRecord forKey:(NSString *)key
{
    BOOL supportsAdding;
    if(![self respondsToKey:key supportsAdding:&supportsAdding] || !supportsAdding)
        return;
    Class partnerClass = [aRecord[0] class];
    NSString *joinTableName = [[self class] joinTableNameForModel:[self.record class] and:partnerClass];
    NSString *selfIdCol     = [[self.record class] idColumn];
    NSString *partnerIdCol  = [[self.record class] idColumnForModel:partnerClass];
    DBTable *joinTable      = self.record.table.database[joinTableName];
    [[[joinTable delete] where:@{ selfIdCol: @(self.record.databaseId), partnerIdCol: @([aRecord databaseId])}] execute];
    if([DBModel enableCache])
        [[self.record readCache] removeObjectForKey:[key pluralizedString]];
}

#pragma mark Accessors
#pragma mark -
- (NSString *)className
{
    if(!self.className)
        return [[DBModel classPrefix] stringByAppendingString:[[self.name singularizedString] stringByCapitalizingFirstLetter]];
    else
        return self.className;
}
@end

@implementation DBModel (HABTM)
- (NSArray *)hasAndBelongsToMany
{
    return [self relationshipsOfType:@"DBRelationshipHABTM"];
}
@end
