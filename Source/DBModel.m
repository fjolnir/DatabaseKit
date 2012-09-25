#import "DBModel.h"
#import "DBTable.h"
#import "DBQuery.h"
#import "DBModelPrivate.h"
#import "NSString+DBAdditions.h"
#import "DBRelationship.h"
#import "DBRelationshipColumn.h"
#import <objc/runtime.h>

static BOOL enableCache  = NO;
static BOOL delayWriting = NO;
static DBNamingStyle namingStyle = DBObjCNamingStyle;

static void *relationshipAssocKey = NULL;

static DBConnection * defaultConnection = nil;
static NSString *classPrefix = nil;

@interface DBModel ()
@property(readwrite, strong) DBTable *table;
@end

@implementation DBModel

+ (void)setDefaultConnection:(DBConnection *)aConnection
{
    @synchronized([DBModel class]) {
        defaultConnection = aConnection;
    }
}
+ (DBConnection *)defaultConnection
{
    return defaultConnection;
}
- (DBConnection *)connection
{
    if(!_connection)
        return [DBModel defaultConnection];
    return _connection;
}
- (void)setConnection:(DBConnection *)aConnection {
    @synchronized(self) {
        _connection = aConnection;
    }
}

+ (void)setClassPrefix:(NSString *)aPrefix
{
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
        value = [self valueForKey:key];
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
        DBLog(@"Error deleting record with id %ld, exception: %@", self.databaseId, e);
    }
    return NO;
}

#pragma mark - Naming style
+ (DBNamingStyle)namingStyle
{
    return namingStyle;
}
+ (void)setNamingStyle:(DBNamingStyle)style
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
+ (id)createWithAttributes:(NSDictionary *)attributes connection:(DBConnection *)connection
{
    // Create a transaction
    @try {
        if(![connection beginTransaction]) {
            [NSException raise:@"DBCreateErrorException" format:@"Couldn't start transaction for connection: %@", connection];
            return nil;
        }
        // Create a blank row (We handle the attributes seperately)
        DBTable *table = [DBTable withConnection:connection name:[self tableName]];
        [[table insert:@{ @"id" : [NSNull null] }] execute];

        NSUInteger rowId = [connection lastInsertId];
        id record = [[self alloc] initWithConnection:connection id:rowId];
        for(NSString *key in [attributes allKeys]) {
            [record sendValue:attributes[key] forKey:key];
        }
        return record;
    }
    @catch (NSException *e) {
        DBDebugLog(@"Error during creation, exception: %@", e);
    }
    @finally {
        [connection endTransaction];
    }

    return nil;
}
+ (id)createWithAttributes:(NSDictionary *)attributes
{
    return [self createWithAttributes:attributes connection:[DBModel defaultConnection]];
}

#pragma mark -
#pragma mark Entry retrieving
- (id)initWithId:(NSUInteger)id
{
    return [self initWithConnection:[DBModel defaultConnection] id:id];
}
- (id)initWithConnection:(DBConnection *)aConnection id:(NSUInteger)id
{
    if(!(self = [self init]))
        return nil;

    self.connection = aConnection;
    self.table      = [DBTable withConnection:aConnection name:[[self class] tableName]];
    self.databaseId = id;

    _readCache   = [[NSMutableDictionary alloc] init];
    _writeCache  = [[NSMutableDictionary alloc] init];
    _addCache    = [[NSMutableArray alloc] init];
    _removeCache = [[NSMutableArray alloc] init];

    // Add the relationships
    self.relationships = [NSMutableArray array];
    DBRelationshipColumn *columnRelationship = [[DBRelationshipColumn alloc] initWithName:nil className:nil record:self];
    [self.relationships addObject:columnRelationship];
    for(__strong DBRelationship *relationship in [[self class] relationships]) {
        relationship = [relationship copyUsingRecord:self];
        [self.relationships addObject:relationship];
    }

    return self;
}

#pragma mark -
#pragma mark Accessors
- (id)valueForKey:(NSString *)key
{
    // Check if we have a cached value and if caching is enabled
    id cached = _readCache[key];
    if(cached && [DBModel enableCache])
        return cached;

    // If not, we retrieve the value, return it and cache it if we should
    id value = [self retrieveRecordForKey:key filter:nil order:nil by:nil limit:nil];
    if(value && [DBModel enableCache])
        _readCache[key] = value;
    return value;
}
- (void)setValue:(id)value forKey:(NSString *)key
{
    if(delayWriting)
        _writeCache[key] = value;
    else
        [self sendValue:value forKey:key];
}

- (id)retrieveRecordForKey:(NSString *)key
                    filter:(id)conditions
                     order:(NSString *)order
                        by:(id)orderByFields
                     limit:(NSNumber *)limit
{
    return [[self relationshipForKey:key] retrieveRecordForKey:key
                                                        filter:conditions
                                                         order:order
                                                            by:orderByFields
                                                         limit:limit];
}
- (void)sendValue:(id)value forKey:(NSString *)key
{
    // Update the cache (should we update it before it's saved to the database, as in: setObject?)
    if([DBModel enableCache])
        _readCache[key] = value;

    DBRelationship *relationship = [self relationshipForKey:key];
    if(relationship)
        [relationship sendRecord:value forKey:key];
}

- (id)objectForKeyedSubscript:(id)key
{
    return [self valueForKey:key];
}
- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key
{
    NSParameterAssert([(NSObject*)key isKindOfClass:[NSString class]]);
    [self setValue:obj forKey:(NSString *)key];
}

// Called by KVC when it doesn't find a property/ivar for a given key.
- (id)valueForUndefinedKey:(NSString *)key
{
    return [self valueForKey:key];
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    [self setValue:value forKey:key];
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
    if([DBModel delayWriting] && !ignoreCache)
        [_addCache addObject:@{@"key": key, @"record": record}];
    else
        [[self relationshipForKey:key] addRecord:record forKey:key];
}
- (void)removeRecord:(id)record forKey:(NSString *)key ignoreCache:(BOOL)ignoreCache
{
    if([DBModel delayWriting] && !ignoreCache)
        [_removeCache addObject:@{@"key": key, @"record": record}];
    else
        [[self relationshipForKey:key] removeRecord:record forKey:key];
}

#pragma mark -
#pragma mark Database interface
- (NSArray *)columns
{
    if(!_columnCache)
        _columnCache = [self.connection columnsForTable:[[self class] tableName]];
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
    NSMutableString *ret = [[self className] mutableCopy];
    if([DBModel classPrefix]) {
        [ret replaceOccurrencesOfString:[DBModel classPrefix]
                             withString:@""
                                options:0
                                  range:NSMakeRange(0, [ret length])];
    }
    ret = (NSMutableString *)[[ret stringByDecapitalizingFirstLetter] pluralizedString];
    if([[self class] namingStyle] == DBRailsNamingStyle)
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
        [description appendFormat:@"%@ = %@\n", column, [self valueForKey:column]];
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

@end
