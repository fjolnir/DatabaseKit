//
//  ARRelationshipBelongsTo.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 30.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import "ARRelationshipBelongsTo.h"
#import "NSString+Inflections.h"
#import "ARBase.h"
#import "ARBasePrivate.h"
#import "ARRelationshipHasMany.h"
#import "ARRelationshipHasOne.h"

@implementation ARRelationshipBelongsTo
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
	if(![self respondsToKey:key])
    return nil;
  Class partnerClass = NSClassFromString([NSString stringWithFormat:@"%@%@", 
                                          [[self.record class] classPrefix], [key stringByCapitalizingFirstLetter]]);
  if(!partnerClass)
  {
    [NSException raise:@"Active record error" format:@"No model class found for key %@! (looked for class named %@)",
		 key, 
		 [NSString stringWithFormat:@"%@%@", [[self.record class] classPrefix],
			[key capitalizedString]]
		 ];
    return nil;
  }
  NSString *idColumn = [[self.record class] idColumnForModel:partnerClass];
  id partnerId = [self.record retrieveValueForKey:idColumn];
  if(![partnerId isEqual:[NSNull null]])
    return [[[partnerClass alloc] initWithConnection:self.record.connection
                                                  id:[partnerId unsignedIntValue]] autorelease];
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
    [self.record sendValue:[NSNumber numberWithUnsignedInt:[aRecord databaseId]]
                    forKey:[[aRecord class] idColumn]];
  // Otherwise we tell the owner to handle the setting (since we need to erase the old relationship)
  else if([ownerHasOneOf containsObject:[self.record className]])
    [aRecord sendValue:self.record forKey:[[[self.record class] tableName] singularizedString]];
  
}
@end

@implementation ARBase (BelongsTo)
- (NSArray *)belongsTo
{
  return [self relationshipsOfType:@"ARRelationshipBelongsTo"];
}
@end