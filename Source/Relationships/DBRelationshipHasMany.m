//
//  DBRelationshipHasMany.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 30.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import "DBRelationshipHasMany.h"
#import "NSString+DBAdditions.h"
#import "DBBase.h"
#import "DBBasePrivate.h"
#import "DBQuery.h"
#import "DBTable.h"

@implementation DBRelationshipHasMany
#pragma mark Key parser
#pragma mark -
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
    Class partnerClass = NSClassFromString([NSString stringWithFormat:@"%@%@",
                                            [[self.record class] classPrefix], [[key singularizedString] capitalizedString]]);
    if(!partnerClass)
    {
        [NSException raise:@"Active record error" format:@"No model class found for key %@! (looked for class named %@)",
		 key,
		 [NSString stringWithFormat:@"%@%@", [[self.record class] classPrefix],
          [key stringByCapitalizingFirstLetter]]
		 ];
        return nil;
    }
    NSString *idColumn = [[self.record class] idColumnForModel:[self.record class]];

    DBTable *partnerTable = [DBTable withConnection:self.record.connection name:[partnerClass tableName]];
    DBQuery *q = [[[partnerTable select:@"id"] where:@{ idColumn: @(self.record.databaseId) }] limit:limit];
    if(conditions)
        q = [q appendWhere:conditions];
    if(order || orderByFields)
        q = [q order:order ? order : DBOrderAscending by:orderByFields];
    NSNumber *anId;
    id partnerRecord;
    NSMutableArray *partners = [NSMutableArray array];
    for(NSDictionary *row in [q execute]) {
        anId = row[@"id"];
        partnerRecord = [[partnerClass alloc] initWithConnection:self.record.connection id:[anId unsignedIntegerValue]];
        [partners addObject:partnerRecord];
    }
    return partners;
}

- (void)sendRecord:(id)aRecord forKey:(NSString *)key
{
    if(![self respondsToKey:key])
        return;
    // aRecord is expected to be an nsarray
    NSArray *oldPartners = [self.record retrieveValueForKey:key];
    for(id partner in oldPartners)
        [partner sendValue:@0
                    forKey:[[self.record class] idColumn]];
	if(!aRecord)
		return;
    for(id partner in aRecord)
        [partner sendValue:@(self.record.databaseId)
                    forKey:[[self.record class] idColumn]];

}
- (void)addRecord:(id)aRecord forKey:(NSString *)key
{
    BOOL supportsAdding;
    if(![self respondsToKey:key supportsAdding:&supportsAdding] || !supportsAdding)
        return;
    [aRecord sendValue:@(self.record.databaseId)
                forKey:[[self.record class] idColumn]];
}
- (void)removeRecord:(id)aRecord forKey:(NSString *)key
{
    BOOL supportsAdding;
    if(![self respondsToKey:key supportsAdding:&supportsAdding] || !supportsAdding)
        return;
    [self.record sendValue:@0U
                    forKey:[[self.record class] idColumn]];
}

#pragma mark Accessors
#pragma mark -
- (NSString *)className
{
    if(![super className])
        return [NSString stringWithFormat:@"%@%@", [DBBase classPrefix], [[self.name singularizedString] capitalizedString]];
    else
        return [super className];
}
@end

@implementation DBBase (HasMany)
+ (void)hasMany:(NSString *)child
{
    [self.relationships addObject:[DBRelationshipHasMany relationshipWithName:child]];
}

- (NSArray *)hasMany
{
    return [self relationshipsOfType:@"DBRelationshipHasMany"];
}
@end