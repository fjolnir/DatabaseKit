//
//  ARRelationshipHasOne.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 30.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import <ActiveRecord/ARRelationshipHasOne.h>
#import "ARRelationshipHasOne.h"
#import "ARBasePrivate.h"
#import "NSString+ARAdditions.h"

@implementation ARRelationshipHasOne
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
										filter:(NSString *)whereSQL 
										 order:(NSString *)orderSQL
										 limit:(NSUInteger)limit
{
	NSArray *array = [super retrieveRecordForKey:key
																				filter:whereSQL
																				 order:orderSQL
																				 limit:limit];
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
    return [NSString stringWithFormat:@"%@%@", [ARBase classPrefix], [self.name stringByCapitalizingFirstLetter]];
  else
    return [super className];
}
@end

@implementation ARBase (HasOne)
+ (void)hasOne:(NSString *)parent
{
    [self.relationships addObject:[ARRelationshipHasOne relationshipWithName:parent]];
}
- (NSArray *)hasOne
{
  return [self relationshipsOfType:@"ARRelationshipHasOne"];
}
@end