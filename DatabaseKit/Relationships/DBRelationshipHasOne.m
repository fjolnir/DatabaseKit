//
//  DBRelationshipHasOne.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 30.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import "DBRelationshipHasOne.h"
#import "../DBModelPrivate.h"
#import "../Utilities/NSString+DBAdditions.h"

@implementation DBRelationshipHasOne
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
    NSArray *array = [super retrieveRecordForKey:key filter:conditions order:order by:orderByFields limit:limit];
  if(!array || [array count] <= 0)
    return nil;
  // Else
  return array[0];
}
- (void)sendRecord:(id)aRecord forKey:(NSString *)key
{
  if(![self respondsToKey:key])
    return;
  id oldPartner = [self retrieveRecordForKey:key];
  if(oldPartner != nil)
    [oldPartner sendValue:@0
                   forKey:[[self.record class] idColumn]];
    
    if(!aRecord)
        return;
  [aRecord sendValue:@(self.record.databaseId)
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

@implementation DBModel (HasOne)
+ (void)hasOne:(NSString *)parent
{
    [self.relationships addObject:[DBRelationshipHasOne relationshipWithName:parent]];
}
- (NSArray *)hasOne
{
  return [self relationshipsOfType:@"DBRelationshipHasOne"];
}
@end