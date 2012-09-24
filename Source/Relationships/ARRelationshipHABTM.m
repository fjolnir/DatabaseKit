//
//  ARRelationshipHABTM.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 9/12/07.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import "ARRelationshipHABTM.h"
#import "ARBase.h"
#import "ARBasePrivate.h"
#import "NSString+ARAdditions.h"

@implementation ARRelationshipHABTM
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
																					[[self.record class] classPrefix], [[key singularizedString] stringByCapitalizingFirstLetter]]);
	if(!partnerClass)
  {
    [NSException raise:@"Active record error" format:@"No model class found for key %@! (looked for class named %@)",
		 key, 
		 [NSString stringWithFormat:@"%@%@", [[self.record class] classPrefix],
			[key stringByCapitalizingFirstLetter]]
		 ];
    return nil;
  }
	NSString *joinTableName = [[self.record class] joinTableNameForModel:[self.record class] and:partnerClass];
	
	NSMutableString *idQuery = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@ INNER JOIN %@ ON %@.id = %@.%@ WHERE %@=:our_id",
								[[self.record class] idColumnForModel:partnerClass], 
								[partnerClass tableName], 
								joinTableName, 
								[partnerClass tableName],
								joinTableName,
								[[self.record class] idColumnForModel:partnerClass],
								[[self.record class] idColumn]];
	
	
	if(whereSQL)
		[idQuery appendFormat:@" AND %@", whereSQL];
	if(orderSQL)
		[idQuery appendFormat:@" ORDER BY %@", orderSQL];
	if(limit > 0)
		[idQuery appendFormat:@" LIMIT %ld", limit];
	
	NSArray *partnerIds = [self.record.connection executeSQL:idQuery
												 substitutions:@{@"our_id": @(self.record.databaseId) } error:nil];
	id partnerRecord;
	NSNumber *anId;
	NSMutableArray *partners = [NSMutableArray array];
	for(NSDictionary *dict in partnerIds)
	{
		anId = dict[[[self.record class] idColumnForModel:partnerClass]];
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

    // aRecord is an array
    Class partnerClass = [aRecord[0] class];
    NSString *joinTableName = [[self class] joinTableNameForModel:[self.record class] and:partnerClass];
    // First empty out the join table
    [self.record.connection executeSQL:[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=:our_id", joinTableName, [[self.record class] idColumn]]
                         substitutions:@{@"our_id": @(self.record.databaseId)}
                                 error:nil];
		if(!aRecord)
			return;
    // Then populate it
    for(ARBase *partner in aRecord)
    {
        [self.record.connection executeSQL:[NSString stringWithFormat:@"INSERT INTO %@(%@, %@) VALUES(:our_id, :their_id)",
                                           joinTableName, [[self class] idColumn], [[partner class] idColumn]]
                            substitutions:@{@"our_id": @(self.record.databaseId),
                                           @"their_id": [NSNumber numberWithUnsignedInt:partner.databaseId]}
                                     error:nil];
    }
    
}
- (void)addRecord:(id)aRecord forKey:(NSString *)key
{
	BOOL supportsAdding;
	if(![self respondsToKey:key supportsAdding:&supportsAdding] || !supportsAdding)
			return;

	// Check if the relationship already exists between us, if it does we shouldn't duplicate it
	// Note to self: maybe we should replace this with a query, it'd be faster but uglier code.
	NSArray *existingPartners = [self.record retrieveValueForKey:key];
	for(id existingPartner in existingPartners)
	{
			if([existingPartner databaseId] == [aRecord databaseId])
					return;
	} 
	NSString *query = [NSString stringWithFormat:@"INSERT INTO %@(%@, %@) VALUES(:our_id, :their_id)", 
										 [[self.record class] joinTableNameForModel:[self.record class] and:[aRecord class]],
										 [[self.record class] idColumn], [[aRecord class] idColumn]];
	[self.record.connection executeSQL:query
                         substitutions:@{@"our_id": @(self.record.databaseId), @"their_id": @([aRecord databaseId])}
                                 error:nil];
}

- (void)removeRecord:(id)aRecord forKey:(NSString *)key
{
    BOOL supportsAdding;
    if(![self respondsToKey:key supportsAdding:&supportsAdding] || !supportsAdding)
        return;
    // Check if the relationship already exists between us, if it does we shouldn't duplicate it
    NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=:our_id AND %@=:their_id",
                       [[self.record.connection class] joinTableNameForModel:[self.record.connection class] and:[aRecord class]],
                       [[self.record.connection class] idColumn], [[aRecord class] idColumn]];
    [self.record.connection executeSQL:query
                             substitutions:@{@"our_id": @(self.record.databaseId),
                                            @"their_id": @([aRecord databaseId])}
                                 error:nil];
}

#pragma mark Accessors
#pragma mark -
- (NSString *)className
{
    if(!self.className)
        return [NSString stringWithFormat:@"%@%@", [ARBase classPrefix], [[self.name singularizedString] stringByCapitalizingFirstLetter]];
    else
        return self.className;
}
@end

@implementation ARBase (HABTM)
- (NSArray *)hasAndBelongsToMany
{
  return [self relationshipsOfType:@"ARRelationshipHABTM"];
}
@end
