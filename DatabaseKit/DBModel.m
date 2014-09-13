#import "DBModel.h"
#import "DBTable.h"
#import "DBQuery.h"
#import "DBModel+Private.h"
#import "Debug.h"
#import "Utilities/NSString+DBAdditions.h"
#import "Relationships/DBRelationship.h"
#import "Relationships/DBRelationshipColumn.h"
#import <objc/runtime.h>
#include <unistd.h>

static BOOL enableCache  = YES;
static BOOL delayWriting = NO;

static void *relationshipAssocKey = NULL;

static NSString *classPrefix = nil;

@interface DBModel ()
@property(readwrite, strong) DBTable *table;
@end

@implementation DBModel

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
    [_table.database.connection beginTransaction];
    NSString *key, *value;
    for(int i = 0; i < [_writeCache count]; ++i) {
        key = [_writeCache allKeys][i];
        value = _writeCache[key];
        [self sendValue:value forKey:key];
    }
    // Apply the add/remove cache
    for(int i = 0; i < [_addCache count]; ++i) {
        key = _addCache[i][@"key"];
        value = _addCache[i][@"record"];
        [self addRecord:value forKey:key ignoreCache:YES];
    }
    for(int i = 0; i < [_removeCache count]; ++i) {
        key = _removeCache[i][@"key"];
        value = _removeCache[i][@"record"];
        [self removeRecord:value forKey:key ignoreCache:YES];
    }
    [_table.database.connection endTransaction];
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
        DBLog(@"Error deleting record with id %ld, exception: %@", (unsigned long)self.databaseId, e);
    }
    return NO;
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

#pragma mark - Entry retrieval

- (id)initWithTable:(DBTable *)aTable databaseId:(NSUInteger)aDatabaseId
{
    if(!(self = [self init]))
        return nil;
    NSParameterAssert(aTable && aDatabaseId > 0);
    self.table      = aTable;
    self.databaseId = aDatabaseId;

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

- (DBQuery *)query
{
    return [_table where:@{ @"id": @(_databaseId) }];
}

#pragma mark -
#pragma mark Accessors
- (id)valueForKey:(NSString *)key
{
    // Check if we have a cached value and if caching is enabled
    id cached;
    if(enableCache && (cached = _readCache[key]))
        return cached;

    // If not, we retrieve the value, return it and cache it if we should
    id value = [[self relationshipForKey:key] retrieveRecordForKey:key];
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

- (void)sendValue:(id)value forKey:(NSString *)key
{
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
        _columnCache = [_table columns];
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
    return ret;
}


#pragma mark - Cosmetics

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@:%p> (stored id: %ld) {\n", [self className], self, (unsigned long)[self databaseId]];
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
