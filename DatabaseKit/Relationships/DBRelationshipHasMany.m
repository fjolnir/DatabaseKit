//
//  DBRelationshipHasMany.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 30.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import "DBRelationshipHasMany.h"
#import "../Utilities/NSString+DBAdditions.h"
#import "../DBModel.h"
#import "../DBModel+Private.h"
#import "../Queries/DBQuery.h"
#import "../DBTable.h"

@implementation DBRelationshipHasMany

- (BOOL)respondsToKey:(NSString *)key
{
    return [key isEqualToString:self.name];
}

- (id)retrieveRecordForKey:(NSString *)key
                    filter:(id)conditions
                     order:(NSString *)order
                        by:(id)orderByFields
                     limit:(NSNumber *)limit
{
    if(![self respondsToKey:key])
        return nil;
    NSString *partnerClassName = [[[self.record class] classPrefix] stringByAppendingString:[[key singularizedString] stringByCapitalizingFirstLetter]];
    Class partnerClass = NSClassFromString(partnerClassName);
    if(!partnerClass)
    {
        [NSException raise:@"DBKit error" format:@"No model class found for key %@! (looked for class named %@)",
                                                 key, partnerClassName];
        return nil;
    }
    NSString *idColumn = [[self.record class] idColumnForModel:[self.record class]];

    DBTable *partnerTable = self.record.table.database[[partnerClass tableName]];
    DBSelectQuery *q = [[[partnerTable select:@[@"id"]] where:@{ idColumn: @(self.record.databaseId) }] limit:limit];
    if(conditions)
        q = [q appendWhere:conditions];
    if(order || orderByFields)
        q = [q order:order ? order : DBOrderAscending by:orderByFields];
    NSNumber *anId;
    id partnerRecord;
    NSMutableArray *partners = [NSMutableArray array];
    for(NSDictionary *row in [q execute]) {
        anId = row[@"id"];
        partnerRecord = [[partnerClass alloc] initWithTable:partnerTable
                                                 databaseId:[anId unsignedIntegerValue]];
        [partners addObject:partnerRecord];
    }
    return partners;
}

- (void)sendRecord:(id)aRecord forKey:(NSString *)key
{
    if(![self respondsToKey:key])
        return;
    // aRecord is expected to be an nsarray
    NSArray *oldPartners = [self.record valueForKey:key];
    for(id partner in oldPartners)
        [partner sendValue:@0
                    forKey:[[self.record class] idColumn]];
    if(!aRecord)
        return;
    for(id partner in aRecord)
        [partner sendValue:@(self.record.databaseId)
                    forKey:[[self.record class] idColumn]];

}


#pragma mark Accessors
#pragma mark -
- (NSString *)className
{
    if(![super className])
        return [[DBModel classPrefix] stringByAppendingString:[[self.name singularizedString] stringByCapitalizingFirstLetter]];
    else
        return [super className];
}
@end

@implementation DBModel (HasMany)
+ (void)hasMany:(NSString *)child
{
    [self.relationships addObject:[DBRelationshipHasMany relationshipWithName:child]];
}

- (NSArray *)hasMany
{
    return [self relationshipsOfType:@"DBRelationshipHasMany"];
}
@end