//
//  DBRelationshipBelongsTo.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 30.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import "DBRelationshipBelongsTo.h"
#import "NSString+DBAdditions.h"
#import "DBModel.h"
#import "DBModelPrivate.h"
#import "DBRelationshipHasMany.h"
#import "DBRelationshipHasOne.h"

@implementation DBRelationshipBelongsTo
#pragma mark Key parser
#pragma mark -
- (BOOL)respondsToKey:(NSString *)key supportsAdding:(BOOL *)supportsAddingRet
{
    if(supportsAddingRet != NULL)
        *supportsAddingRet = NO;
    if([key isEqualToString:[self.name singularizedString]])
        return YES;
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
    NSString *partnerClassName = [NSString stringWithFormat:@"%@%@",
                                  [[self.record class] classPrefix],
                                  [key stringByCapitalizingFirstLetter]];
    Class partnerClass = NSClassFromString(partnerClassName);;
    if(!partnerClass)
    {
        [NSException raise:@"Active record error" format:@"No model class found for key %@! (looked for class named %@)", key, partnerClassName];
        return nil;
    }
    NSString *idColumn = [[self.record class] idColumnForModel:partnerClass];
    id partnerId = [self.record valueForKey:idColumn];
    if(![partnerId isEqual:[NSNull null]])
        return [[partnerClass alloc] initWithConnection:self.record.connection
                                                      id:[partnerId unsignedIntValue]];
    return nil;
}
- (void)sendRecord:(id)aRecord forKey:(NSString *)key
{
    if(![self respondsToKey:key])
        return;
    // If the owner has many of us we just set our ownerId to it's id
    NSArray *ownerHasManyOf = [[aRecord hasMany] valueForKey:@"className"];
    NSArray *ownerHasOneOf = [[aRecord hasOne] valueForKey:@"className"];

    Class partnerClass = NSClassFromString([NSString stringWithFormat:@"%@%@",
                                            [[self.record class] classPrefix], [key stringByCapitalizingFirstLetter]]);
    if(!aRecord && partnerClass)
        [self.record sendValue:0 forKey:[partnerClass idColumn]];
    else if([ownerHasManyOf containsObject:[self.record className]])
        [self.record sendValue:@([aRecord databaseId])
                        forKey:[[aRecord class] idColumn]];
    // Otherwise we tell the owner to handle the setting (since we need to erase the old relationship)
    else if([ownerHasOneOf containsObject:[self.record className]])
        [aRecord sendValue:self.record forKey:[[[self.record class] tableName] singularizedString]];

}
@end

@implementation DBModel (BelongsTo)
+ (void)belongsTo:(NSString *)owner
{
    [self.relationships addObject:[DBRelationshipBelongsTo relationshipWithName:owner]];
}
- (NSArray *)belongsTo
{
    return [self relationshipsOfType:@"DBRelationshipBelongsTo"];
}
@end