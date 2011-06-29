//
//  ARRelationshipHasMany.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 30.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import "ARRelationshipHasMany.h"
#import "NSString+Inflections.h"
#import "ARBase.h"
#import "ARBasePrivate.h"


@implementation ARRelationshipHasMany
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
										filter:(NSString *)whereSQL 
										 order:(NSString *)orderSQL
										 limit:(NSUInteger)limit
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
  NSMutableString *query = [NSMutableString stringWithFormat:@"SELECT id FROM %@ WHERE %@ = :our_id", 
																														[partnerClass tableName], idColumn];
	if(whereSQL)
		[query appendFormat:@" AND %@", whereSQL];
	if(orderSQL)
		[query appendFormat:@" ORDER BY %@", orderSQL];
	if(limit > 0)
		[query appendFormat:@" LIMIT %d", limit];
	
  NSArray *ids = [self.record.connection executeSQL:query
									substitutions:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:self.record.databaseId]
																														forKey:@"our_id"]];
  NSNumber *anId;
  id partnerRecord;
  NSMutableArray *partners = [NSMutableArray array];
  for(NSDictionary *dict in ids)
  {
    anId = [dict objectForKey:@"id"];
    partnerRecord = [[partnerClass alloc] initWithConnection:self.record.connection 
                                                          id:[anId unsignedIntValue]];
    [partners addObject:[partnerRecord autorelease]];
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
    [partner sendValue:[NSNumber numberWithInt:0]
                forKey:[[self.record class] idColumn]];
	if(!aRecord)
		return;
  for(id partner in aRecord)
    [partner sendValue:[NSNumber numberWithUnsignedInt:self.record.databaseId]
                forKey:[[self.record class] idColumn]];
    
}
- (void)addRecord:(id)aRecord forKey:(NSString *)key
{
  BOOL supportsAdding;
  if(![self respondsToKey:key supportsAdding:&supportsAdding] || !supportsAdding)
    return;
  [aRecord sendValue:[NSNumber numberWithUnsignedInt:[self.record databaseId]]
              forKey:[[self.record class] idColumn]];
}
- (void)removeRecord:(id)aRecord forKey:(NSString *)key
{
  BOOL supportsAdding;
  if(![self respondsToKey:key supportsAdding:&supportsAdding] || !supportsAdding)
    return;
  [record sendValue:[NSNumber numberWithUnsignedInt:0]
             forKey:[[self.record class] idColumn]];
}

#pragma mark Accessors
#pragma mark -
- (NSString *)className
{
  if(!className)
    return [NSString stringWithFormat:@"%@%@", [ARBase classPrefix], [[self.name singularizedString] capitalizedString]];
  else
    return className;
}
@end

@implementation ARBase (HasMany)
- (NSArray *)hasMany
{
  return [self relationshipsOfType:@"ARRelationshipHasMany"];
}
@end