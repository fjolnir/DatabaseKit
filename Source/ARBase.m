//
//  ARBase.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//
#import "ARBase.h"
#import "ARBasePrivate.h"
#import "NSString+Inflections.h"
#import "ARRelationship.h"
#import "ARRelationshipColumn.h"

static BOOL enableCache  = NO;
static BOOL delayWriting = NO;
static ARNamingStyle namingStyle = ARRailsNamingStyle;

// Relationships
//  Stored as dictionaries containing arrays of relationships
//  They are keyed by [self class] (objective-c really needs class variables)
static NSMutableDictionary *globalRelationships = nil;

static id<ARConnection> defaultConnection = nil;
static NSString *classPrefix = nil;

@implementation ARBase
@synthesize connection, databaseId, relationships;

+ (void)setDefaultConnection:(id<ARConnection>)aConnection
{
	[aConnection retain];
	[defaultConnection release];
  defaultConnection = aConnection;
}
+ (id<ARConnection>)defaultConnection
{
  return defaultConnection;
}
- (id<ARConnection>)connection
{
	if(!connection)
		return [ARBase defaultConnection];

	return connection;
}

+ (void)setClassPrefix:(NSString *)aPrefix
{
  [aPrefix retain];
  [classPrefix release];
  classPrefix = aPrefix;
}
+ (NSString *)classPrefix
{
  return classPrefix ? classPrefix : @"";
}

#pragma mark -
#pragma mark Caching
+ (BOOL)enableCache
{
	return enableCache;
}
+ (void)setEnableCache:(BOOL)flag
{
	enableCache = flag;
}
- (void)refreshCache
{
	id value = nil;
	for(NSString *key in [readCache allKeys])
	{
		value = [self retrieveValueForKey:key];
		if(value)
			[readCache setObject:value forKey:key];
		else
			[readCache removeObjectForKey:key];
	}
}

#pragma mark -
#pragma mark Delayed writing
+ (BOOL)delayWriting
{
	return delayWriting;
}
+ (void)setDelayWriting:(BOOL)flag
{
	delayWriting = flag;
}
- (void)save
{
	[self.connection beginTransaction];
	NSString *key, *value;
	for(int i = 0; i < [writeCache count]; ++i)
	{
		key = [[writeCache allKeys] objectAtIndex:i];
		value = [writeCache objectForKey:key];
		[self sendValue:value forKey:key];
	}
	// Apply the add/remove cache
	for(int i = 0; i < [addCache count]; ++i)
	{
		key = [[addCache objectAtIndex:i] objectForKey:@"key"];
		value = [[addCache objectAtIndex:i] objectForKey:@"record"];
		[self addRecord:value forKey:key ignoreCache:YES];
	}
	for(int i = 0; i < [removeCache count]; ++i)
	{
		key = [[removeCache objectAtIndex:i] objectForKey:@"key"];
		value = [[removeCache objectAtIndex:i] objectForKey:@"record"];
		[self removeRecord:value forKey:key ignoreCache:YES];
	}
	[self.connection endTransaction];
	// purge the cache so we don't write it again
	[addCache removeAllObjects];
	[removeCache removeAllObjects];
	[writeCache removeAllObjects];
}

- (BOOL)destroy
{
	@try
	{
		[self.connection executeSQL:[NSString stringWithFormat:@"DELETE FROM %@ WHERE id = :id", [[self class] tableName]]
									substitutions:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:self.databaseId] forKey:@"id"]];
		[self autorelease];
		return YES;
	}
	@catch(NSException *e)
	{
    ARLog(@"Error deleting record with id %d, exception: %@", self.databaseId, e);
	}
	return NO;
}

#pragma mark -
#pragma mark Naming style
+ (ARNamingStyle)namingStyle
{
	return namingStyle;
}
+ (void)setNamingStyle:(ARNamingStyle)style
{
	namingStyle = style;
}

#pragma mark -
#pragma mark Init
+ (void)initialize
{
  if(globalRelationships == nil)
    globalRelationships = [[NSMutableDictionary alloc] init];
}

#pragma mark -
#pragma mark Relationships
+ (NSMutableArray *)relationships
{
  if(![globalRelationships objectForKey:[self className]])
    [globalRelationships setObject:[NSMutableArray array] forKey:[self className]];

  return [globalRelationships objectForKey:[self className]];
}

#pragma mark -
#pragma mark Entry creation
+ (id)createWithAttributes:(NSDictionary *)attributes connection:(id<ARConnection>)connection
{
  // Create a transaction
  @try
  {
    if(![connection beginTransaction])
		{
			[NSException raise:@"ARCreateErrorException" format:@"Couldn't start transaction for connection: %@", connection];
      return nil;
		}
    // Create a blank row (We handle the attributes seperately)
    NSString *creationQuery = [NSString stringWithFormat:@"INSERT INTO %@(id) VALUES(NULL)", [self tableName]];
    [connection executeSQL:creationQuery
             substitutions:nil];

    NSUInteger rowId = [connection lastInsertId];
    id record = [[self alloc] initWithConnection:connection id:rowId];
    for(NSString *key in [attributes allKeys])
    {
      [record sendValue:[attributes objectForKey:key] forKey:key];
    }
    return [record autorelease];
  }
  @catch (NSException *e) {
    ARDebugLog(@"Error during creation, exception: %@", e);
  }
  @finally {
    [connection endTransaction];
  }
  
  return nil;
}
+ (id)createWithAttributes:(NSDictionary *)attributes
{
  return [self createWithAttributes:attributes connection:[ARBase defaultConnection]];
}

#pragma mark -
#pragma mark Entry retrieving
- (id)initWithId:(NSUInteger)id
{
  return [self initWithConnection:[ARBase defaultConnection] id:id];
}
- (id)initWithConnection:(id<ARConnection>)aConnection id:(NSUInteger)id
{
  if(![self init])
    return nil;
  
  self.connection = aConnection;
  self.databaseId = id;
	
	readCache = [[NSMutableDictionary alloc] init];
	writeCache = [[NSMutableDictionary alloc] init];
	addCache = [[NSMutableArray alloc] init];
	removeCache = [[NSMutableArray alloc] init];
  
  // Add the relationships
  self.relationships = [NSMutableArray array];
  ARRelationshipColumn *columnRelationship = [ARRelationshipColumn relationshipWithName:nil className:nil];
  columnRelationship.record = self;
  [self.relationships addObject:columnRelationship];
  for(ARRelationship *relationship in [[self class] relationships])
  {
    relationship = [relationship copy];
    relationship.record = self;
    [self.relationships addObject:relationship];
    [relationship release];
  }

  return self;
}

#pragma mark -
#pragma mark Accessors
- (id)retrieveValueForKey:(NSString *)key
{
	// Check if we have a cached value and if caching is enabled
	id cached = [readCache objectForKey:key];
	if(cached && [ARBase enableCache])
		return cached;
	
	// If not, we retrieve the value, return it and cache it if we should
	id value = [self retrieveRecordForKey:key filter:nil order:nil limit:0];
	if(value && [ARBase enableCache])
		[readCache setObject:value forKey:key];
  return value;
}
- (id)retrieveRecordForKey:(NSString *)key 
										filter:(NSString *)whereSQL 
										 order:(NSString *)orderSQL
										 limit:(NSUInteger)limit
{
	ARRelationship *relationship = [self relationshipForKey:key];
	id value = [relationship retrieveRecordForKey:key filter:whereSQL order:orderSQL limit:limit];

  return value;
}
- (void)sendValue:(id)value forKey:(NSString *)key
{
	// Update the cache (should we update it before it's saved to the database, as in: setObject?)
	if([ARBase enableCache])
		[readCache setObject:value forKey:key]; 
	
  ARRelationship *relationship = [self relationshipForKey:key];
	if(relationship)
		[relationship sendRecord:value forKey:key];
}
- (void)setObject:(id)obj forKey:(NSString *)key
{
	if(delayWriting)
		[writeCache setObject:obj forKey:key];
	else
		[self sendValue:obj forKey:key];
}
- (id)valueForKey:(NSString *)key
{
  return [self retrieveValueForKey:key];
}
- (id)valueForUndefinedKey:(NSString *)key
{
  return [self retrieveValueForKey:key];
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
  [self setObject:value forKey:key];
}

// This accessor adds a record to either a has many or has and belongs to many relationship
- (void)addRecord:(id)record forKey:(NSString *)key
{
	[self addRecord:record forKey:key ignoreCache:NO];

}
// This accessor removes a record from either a has many or has and belongs to many relationship
- (void)removeRecord:(id)record forKey:(NSString *)key
{
	[self removeRecord:record forKey:key ignoreCache:NO];
}
- (void)addRecord:(id)record forKey:(NSString *)key ignoreCache:(BOOL)ignoreCache
{
	if([ARBase delayWriting] && !ignoreCache)
		[addCache addObject:[NSDictionary dictionaryWithObjectsAndKeys:key, @"key", record, @"record"]];
	else
		[[self relationshipForKey:key] addRecord:record forKey:key];
}
- (void)removeRecord:(id)record forKey:(NSString *)key ignoreCache:(BOOL)ignoreCache
{
	if([ARBase delayWriting] && !ignoreCache)
		[removeCache addObject:[NSDictionary dictionaryWithObjectsAndKeys:key, @"key", record, @"record"]];
	else
		[[self relationshipForKey:key] removeRecord:record forKey:key];
}

#pragma mark -
#pragma mark Database interface
- (NSArray *)columns
{
	if(!columnCache)
		columnCache = [[self.connection columnsForTable:[[self class] tableName]] retain];
	return columnCache;
}
+ (NSString *)idColumnForModel:(Class)modelClass
{
  return [NSString stringWithFormat:@"%@Id", [[modelClass tableName] singularizedString]];
}
+ (NSString *)idColumn
{
  return [self idColumnForModel:self];
}
+ (NSString *)tableName
{
  NSMutableString *ret = [[[self className] mutableCopy] autorelease];
  if([ARBase classPrefix])
  {
    [ret replaceOccurrencesOfString:[ARBase classPrefix]
                         withString:@""
                            options:0
                              range:NSMakeRange(0, [ret length])];
  }
  ret = (NSMutableString *)[[ret stringByDecapitalizingFirstLetter] pluralizedString];
	if([[self class] namingStyle] == ARRailsNamingStyle)
		return [ret underscoredString];
	return ret;
}
+ (NSString *)joinTableNameForModel:(Class)firstModel and:(Class)secondModel
{
  NSString *firstTableName  = [firstModel tableName];
  NSString *secondTableName = [secondModel tableName];
  if([firstTableName compare:secondTableName options:NSForcedOrderingSearch] == NSOrderedAscending)
    return [NSString stringWithFormat:@"%@_%@", firstTableName, secondTableName]; // Heh, the format kinda looks like a smilie
  else
    return [NSString stringWithFormat:@"%@_%@", secondTableName, firstTableName]; 
}
- (BOOL)beginTransaction
{
  return [self.connection beginTransaction];
}
- (BOOL)endTransaction
{
  return [self.connection endTransaction];
}

#pragma mark -
#pragma mark Cosmetics
- (NSString *)description
{
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@:0x%x> (stored id: %d) {\n", [self className], self, [self databaseId]];
  for(NSString *column in [self columns])
  {
    [description appendFormat:@"%@ = %@\n", column, [self retrieveValueForKey:column]];
  }
  [description appendString:@"}"];
  return description;
}
- (BOOL)isEqual:(id)anObject
{
  if(![anObject isMemberOfClass:[self class]])
    return NO;
  if([anObject databaseId] != [self databaseId])
    return NO;
  if(![[[anObject class] tableName] isEqualToString:[[self class] tableName]])
    return NO;
  return YES;
}

#pragma mark -
#pragma mark Cleanup
- (void)dealloc
{
  [self.connection release];
  [self.relationships release];
	
	[writeCache release];
	[readCache release];
	[addCache release];
	[removeCache release];
  
  [super dealloc];
}

@end
