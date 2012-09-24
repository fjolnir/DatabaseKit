#import "ARBase.h"
#import "ARTable.h"
#import "ARQuery.h"
#import "ARBasePrivate.h"
#import "NSString+ARAdditions.h"
#import "ARRelationship.h"
#import "ARRelationshipColumn.h"
#import <objc/runtime.h>

static BOOL enableCache  = NO;
static BOOL delayWriting = NO;
static ARNamingStyle namingStyle = ARObjCNamingStyle;

static void *relationshipAssocKey = NULL;

static id<ARConnection> defaultConnection = nil;
static NSString *classPrefix = nil;

@interface ARBase ()
@property(readwrite, retain) ARTable *table;
@end

@implementation ARBase

+ (void)setDefaultConnection:(id<ARConnection>)aConnection
{
    @synchronized([ARBase class]) {
        [aConnection retain];
        [defaultConnection release];
        defaultConnection = aConnection;
    }
}
+ (id<ARConnection>)defaultConnection
{
    return defaultConnection;
}
- (id<ARConnection>)connection
{
	if(!_connection)
		return [ARBase defaultConnection];
	return _connection;
}
- (void)setConnection:(id<ARConnection>)aConnection {
    @synchronized(self) {
        [aConnection retain];
        [_connection release];
        _connection = aConnection;
    }
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
	for(NSString *key in [_readCache allKeys])
	{
		value = [self retrieveValueForKey:key];
		if(value)
			_readCache[key] = value;
		else
			[_readCache removeObjectForKey:key];
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
	for(int i = 0; i < [_writeCache count]; ++i)
	{
		key = [_writeCache allKeys][i];
		value = _writeCache[key];
		[self sendValue:value forKey:key];
	}
	// Apply the add/remove cache
	for(int i = 0; i < [_addCache count]; ++i)
	{
		key = _addCache[i][@"key"];
		value = _addCache[i][@"record"];
		[self addRecord:value forKey:key ignoreCache:YES];
	}
	for(int i = 0; i < [_removeCache count]; ++i)
	{
		key = _removeCache[i][@"key"];
		value = _removeCache[i][@"record"];
		[self removeRecord:value forKey:key ignoreCache:YES];
	}
	[self.connection endTransaction];
	// purge the cache so we don't write it again
	[_addCache    removeAllObjects];
	[_removeCache removeAllObjects];
	[_writeCache  removeAllObjects];
}

- (BOOL)destroy
{
	@try {
        [[[_table delete] where:@{ @"id": @(_databaseId) }] execute];
		return YES;
	}
	@catch(NSException *e) {
        ARLog(@"Error deleting record with id %ld, exception: %@", self.databaseId, e);
	}
	return NO;
}

#pragma mark - Naming style
+ (ARNamingStyle)namingStyle
{
	return namingStyle;
}
+ (void)setNamingStyle:(ARNamingStyle)style
{
	namingStyle = style;
}

#pragma mark - Relationships
+ (NSMutableArray *)relationships
{
    NSMutableArray *relationships = objc_getAssociatedObject(self, &relationshipAssocKey);
    if(!relationships) {
        @synchronized(self) {
            if((relationships = objc_getAssociatedObject(self, &relationshipAssocKey)))
                return relationships;
            relationships = [NSMutableArray array];
            objc_setAssociatedObject(self, &relationshipAssocKey, relationships, OBJC_ASSOCIATION_RETAIN);
        }
    }
    return relationships;
}

#pragma mark -
#pragma mark Entry creation
+ (id)createWithAttributes:(NSDictionary *)attributes connection:(id<ARConnection>)connection
{
    // Create a transaction
    @try {
        if(![connection beginTransaction]) {
			[NSException raise:@"ARCreateErrorException" format:@"Couldn't start transaction for connection: %@", connection];
            return nil;
		}
        // Create a blank row (We handle the attributes seperately)
        ARTable *table = [ARTable withConnection:connection name:[self tableName]];
        [[table insert:@{ @"id" : [NSNull null] }] execute];

        NSUInteger rowId = [connection lastInsertId];
        id record = [[self alloc] initWithConnection:connection id:rowId];
        for(NSString *key in [attributes allKeys]) {
            [record sendValue:attributes[key] forKey:key];
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
    if(!(self = [self init]))
        return nil;

    self.connection = aConnection;
    self.table      = [ARTable withConnection:aConnection name:[[self class] tableName]];
    self.databaseId = id;

	_readCache   = [[NSMutableDictionary alloc] init];
	_writeCache  = [[NSMutableDictionary alloc] init];
	_addCache    = [[NSMutableArray alloc] init];
	_removeCache = [[NSMutableArray alloc] init];

    // Add the relationships
    self.relationships = [NSMutableArray array];
    ARRelationshipColumn *columnRelationship = [[ARRelationshipColumn alloc] initWithName:nil className:nil record:self];
    [self.relationships addObject:columnRelationship];
    [columnRelationship release];
    for(ARRelationship *relationship in [[self class] relationships]) {
        relationship = [relationship copyUsingRecord:self];
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
	id cached = _readCache[key];
	if(cached && [ARBase enableCache])
		return cached;

	// If not, we retrieve the value, return it and cache it if we should
	id value = [self retrieveRecordForKey:key filter:nil order:nil limit:0];
	if(value && [ARBase enableCache])
		_readCache[key] = value;
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
		_readCache[key] = value;

    ARRelationship *relationship = [self relationshipForKey:key];
	if(relationship)
		[relationship sendRecord:value forKey:key];
}
- (void)setObject:(id)obj forKey:(NSString *)key
{
	if(delayWriting)
		_writeCache[key] = obj;
	else
		[self sendValue:obj forKey:key];
}
- (id)valueForKey:(NSString *)key
{
    return [self retrieveValueForKey:key];
}
// Called by KVC when it doesn't find a property/ivar for a given key.
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
		[_addCache addObject:@{@"key": key, @"record": record}];
	else
		[[self relationshipForKey:key] addRecord:record forKey:key];
}
- (void)removeRecord:(id)record forKey:(NSString *)key ignoreCache:(BOOL)ignoreCache
{
	if([ARBase delayWriting] && !ignoreCache)
		[_removeCache addObject:@{@"key": key, @"record": record}];
	else
		[[self relationshipForKey:key] removeRecord:record forKey:key];
}

#pragma mark -
#pragma mark Database interface
- (NSArray *)columns
{
	if(!_columnCache)
		_columnCache = [[self.connection columnsForTable:[[self class] tableName]] retain];
	return _columnCache;
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
    if([ARBase classPrefix]) {
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

#pragma mark - Cosmetics

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@:%p> (stored id: %ld) {\n", [self className], self, [self databaseId]];
    for(NSString *column in [self columns]) {
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

#pragma mark - Cleanup

- (void)dealloc
{
    [_connection release];
    [_relationships release];
	
	[_writeCache release];
	[_readCache release];
	[_addCache release];
	[_removeCache release];
	if(_columnCache)
		[_columnCache release];
    
    [super dealloc];
}
@end
