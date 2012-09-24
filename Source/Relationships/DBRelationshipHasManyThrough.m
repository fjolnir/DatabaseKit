//
//  DBRelationshipHasManyThrough.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 18.4.2008.
//  Copyright 2008 Fjölnir Ásgeirsson. All rights reserved.
//

#import "DBRelationshipHasManyThrough.h"
#import "NSString+DBAdditions.h"
#import "DBBasePrivate.h"

@interface DBRelationshipHasManyThrough ()
@property(readwrite, strong) NSString *proxyKey;
@end

@implementation DBRelationshipHasManyThrough

+ (id)relationshipWithName:(NSString *)aName className:(NSString *)aClassName through:(NSString *)aProxyKey
{
	DBRelationshipHasManyThrough *ret = [[self alloc] initWithName:aName className:aClassName through:aProxyKey];
	return ret;
}
+ (id)relationshipWithName:(NSString *)aName through:(NSString *)aProxyKey
{
	return [self relationshipWithName:aName className:nil through:aProxyKey];
}
- (id)initWithName:(NSString *)aName className:(NSString *)aClassName through:(NSString *)aProxyKey
{
	if(!(self = [super initWithName:aName className:aClassName record:nil]))
        return nil;

	self.proxyKey  = aProxyKey;

    return self;
}
- (id)initWithName:(NSString *)aName className:(NSString *)aClassName
{
	[NSException raise:@"DBBase error" format:@"You must create a has many through relationship using relationshipWithName:className:through:"];
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
                    filter:(id)conditions
                     order:(NSString *)order
                        by:(id)orderByFields
                     limit:(NSNumber *)limit
{
	if(![self respondsToKey:key])
		return nil;
	NSMutableArray *partners = [NSMutableArray array];
	id currentPartners;
	for(DBBase *proxy in [self.record retrieveValueForKey:_proxyKey])
	{
		currentPartners = [proxy retrieveRecordForKey:self.name filter:conditions order:order by:orderByFields limit:limit];
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
    DBRelationshipHasManyThrough *ret = [super copyWithZone:zone];
    ret.proxyKey = _proxyKey;
    return ret;
}
#pragma mark -
#pragma mark Cosmetics
- (NSString *)description
{
    return [NSString stringWithFormat:@"{ %@ Name: %@ through: %@ }", [super description], self.name, self.proxyKey];
}
@end

@implementation DBBase (HasManyThrough)
+ (void)hasMany:(NSString *)child through:(NSString *)middleMan
{
    [self.relationships addObject:[DBRelationshipHasManyThrough relationshipWithName:child through:middleMan]];
}
- (NSArray *)hasManyThrough
{
    return [self relationshipsOfType:@"DBRelationshipHasManyThrough"];
}
@end