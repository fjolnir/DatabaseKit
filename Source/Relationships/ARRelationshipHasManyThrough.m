//
//  ARRelationshipHasManyThrough.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 18.4.2008.
//  Copyright 2008 Fjölnir Ásgeirsson. All rights reserved.
//

#import "ARRelationshipHasManyThrough.h"
#import "NSString+Inflections.h"
#import "ARBasePrivate.h"

@implementation ARRelationshipHasManyThrough
@synthesize proxyKey;
+ (id)relationshipWithName:(NSString *)aName className:(NSString *)aClassName through:(NSString *)aProxyKey
{
	ARRelationshipHasManyThrough *ret = [[self alloc] initWithName:aName className:aClassName through:aProxyKey];
	return [ret autorelease];
}
+ (id)relationshipWithName:(NSString *)aName through:(NSString *)aProxyKey
{
	return [self relationshipWithName:aName className:nil through:aProxyKey];
}
- (id)initWithName:(NSString *)aName className:(NSString *)aClassName through:(NSString *)aProxyKey
{
	if(!(self = [super init]))
    return nil;
  self.name = aName;
  self.className = aClassName;
	self.proxyKey = aProxyKey;
  
  return self;
}
- (id)initWithName:(NSString *)aName className:(NSString *)aClassName
{
	[NSException raise:@"ARBase error" format:@"You must create a has many through relationship using relationshipWithName:className:through:"];
	return nil;
}	

- (BOOL)respondsToKey:(NSString *)key supportsAdding:(BOOL *)supportsAddingRet
{
	BOOL ret = [super respondsToKey:key supportsAdding:NULL];
	if(supportsAddingRet)
		*supportsAddingRet = NO;
	return ret;
}

- (id)retrieveRecordForKey:(NSString *)key 
                    filter:(NSString *)whereSQL 
                     order:(NSString *)orderSQL
                     limit:(NSUInteger)limit
{
	if(![self respondsToKey:key])
		return nil;
	NSMutableArray *partners = [NSMutableArray array];
	id currentPartners;
	for(ARBase *proxy in [self.record retrieveValueForKey:proxyKey])
	{
		currentPartners = [proxy retrieveRecordForKey:self.name filter:whereSQL order:orderSQL limit:limit];
		if([currentPartners isKindOfClass:[NSArray class]])
			[partners addObjectsFromArray:currentPartners];
		else
			[partners addObject:currentPartners];
	}
	return partners;
}
- (void)sendRecord:(id)aRecord forKey:(NSString *)key
{
  if(![self respondsToKey:key])
    return;
	[NSException raise:@"Writing not supported" format:@"has many through relationships don't support writing"];
}
- (void)addRecord:(id)aRecord forKey:(NSString *)key
{
  BOOL supportsAdding;
  if(![self respondsToKey:key supportsAdding:&supportsAdding] || !supportsAdding)
    return;
	[NSException raise:@"Writing not supported" format:@"has many through relationships don't support writing"];

}
- (void)removeRecord:(id)aRecord forKey:(NSString *)key
{
	[self addRecord:aRecord forKey:key]; // It's the same thing.
}

#pragma mark -
#pragma mark Copying
- (id)copyWithZone:(NSZone *)zone
{
  ARRelationship *ret = [[[self class] allocWithZone:zone] initWithName:self.name className:self.className through:self.proxyKey];
  ret.record = self.record;
  return ret; 
}
#pragma mark -
#pragma mark Cosmetics
- (NSString *)description
{
  return [NSString stringWithFormat:@"{ %@ Name: %@ through: %@ }", [super description], self.name, self.proxyKey];
}
@end

@implementation ARBase (HasManyThrough)
- (NSArray *)hasManyThrough
{
  return [self relationshipsOfType:@"ARRelationshipHasManyThrough"];
}
@end