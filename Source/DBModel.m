#import "DBModel+Private.h"
#import "DB+Private.h"
#import "DBSelectQuery.h"
#import "DBInsertQuery.h"
#import "DBDeleteQuery.h"
#import "DBBatchQuery.h"
#import "DBTable.h"
#import "DBQuery.h"
#import "DBUtilities.h"
#import "NSString+DBAdditions.h"
#import "DBIntrospection.h"
#import "DBOrderedDictionary.h"
#import <objc/runtime.h>
#import <unistd.h>
#import <libkern/OSAtomic.h>

NSString * const kDBUUIDKey = @"UUID";

@implementation DBModel {
    DB *_database;
    DBOrderedDictionary *_pendingQueries;
    OSSpinLock _dbLock;
}
@dynamic saved, hasChanges;

+ (BOOL)_attributeIsRelationship:(DBPropertyAttributes *)attributes
                        isPlural:(BOOL *)outIsPlural
                    relatedClass:(Class *)outRelatedKlass
{
    if(!attributes->klass || ![self.savedKeys containsObject:@(attributes->name)])
        return NO;
    if([attributes->klass isSubclassOfClass:[DBModel class]]) {
        if(outIsPlural)
            *outIsPlural = NO;
        if(outRelatedKlass)
            *outRelatedKlass = attributes->klass;
        return YES;
    } else if(attributes->hasProtocolList && [attributes->klass isSubclassOfClass:[NSSet class]]) {
        for(NSString *protocolName in DBProtocolNamesInTypeEncoding(attributes->encoding)) {
            Class klass = NSClassFromString(protocolName);
            if([klass isSubclassOfClass:[DBModel class]]) {
                if(outIsPlural)
                    *outIsPlural = YES;
                if(outRelatedKlass)
                    *outRelatedKlass = klass;
                return YES;
            }
        }
    }
    return NO;
}

+ (void)initialize
{
    if([NSStringFromClass(self) hasPrefix:@"NSKVONotifying"])
        return; // TODO: Find a better way of handling this.

    for(NSString *key in self.savedKeys) {
        DBPropertyAttributes *attrs = DBAttributesForProperty(self, class_getProperty(self, [key UTF8String]));
        Class relatedKlass;
        BOOL pluralRelationship;
        if([self _attributeIsRelationship:attrs isPlural:&pluralRelationship relatedClass:&relatedKlass]) {
            Method getter = class_getInstanceMethod(self, attrs->getter);
            method_setImplementation(getter, imp_implementationWithBlock(^(DBModel *obj) {
                DBModel *value = object_getIvar(obj, attrs->ivar);
                if(!value) {
                    DBSelectQuery *query = [obj _selectQueryForRelatedKey:key
                                                                    class:relatedKlass
                                                                 isPlural:pluralRelationship];
                    value = pluralRelationship
                          ? [NSSet setWithArray:[query execute]]
                          : [query firstObject];
                    object_setIvar(obj, attrs->ivar, value);
                }
                return value;
            }));
        } else
            free(attrs);
    }
}

+ (NSSet *)savedKeys
{
    static void *savedKeysKey = &savedKeysKey;

    if(self == [DBModel class])
        return nil;

    NSSet *savedKeys = objc_getAssociatedObject(self, savedKeysKey);
    if(!savedKeys) {
        NSSet *excludedKeys = [self excludedKeys];
        NSMutableSet *result = [NSMutableSet setWithObject:kDBUUIDKey];

        DBIteratePropertiesForClass(self, ^(DBPropertyAttributes *attrs) {
            NSString *key = @(attrs->name);
            
            if(!attrs->dynamic &&
               ![DBModel instancesRespondToSelector:attrs->getter] &&
               ![excludedKeys containsObject:key])
            {
                BOOL canBeSaved = attrs->encoding[0] != _C_ID
                               || [attrs->klass isSubclassOfClass:[DBModel class]]
                               || DBPropertyConformsToProtocol(attrs, @protocol(NSCoding));
                if(canBeSaved)
                    [result addObject:key];
            }
        });
        savedKeys = result;
        objc_setAssociatedObject(self, savedKeysKey, result, OBJC_ASSOCIATION_RETAIN);
    }
    return savedKeys.count > 0
         ? savedKeys
         : nil;
}

+ (NSSet *)excludedKeys
{
    return nil;
}

+ (NSString *)joinTableNameForKey:(NSString *)key
{
    return [NSString stringWithFormat:@"%@-%@", [self tableName], key];
}

+ (NSArray *)indices
{
    return nil;
}

+ (NSArray *)constraintsForKey:(NSString *)key
{
    // Check if we respond to the selector `constraintsFor<Key>`
    SEL selector = DBCapitalizedSelector(@"constraintsFor", key);
    if([self respondsToSelector:selector]) {
        id (*imp)(id,SEL) = (void*)[self methodForSelector:selector];
        return imp(self, selector);
    } else {
        // Scalar properties should not be nullable
        DBPropertyAttributes *attrs = DBAttributesForProperty(self, class_getProperty(self, key.UTF8String));
        BOOL const isScalar = (attrs && attrs->encoding[0] != _C_ID);
        free(attrs);
        if(isScalar)
            return @[[DBNotNullConstraint new],
                     [DBDefaultConstraint defaultConstraintWithValue:@0]];
        else
            return nil;
    }
}

+ (NSArray *)constraintsForUUID
{
    return @[[DBPrimaryKeyConstraint primaryKeyConstraintWithOrder:DBOrderAscending
                                                     autoIncrement:NO
                                                        onConflict:DBConflictActionFail],
             [DBNotNullConstraint new]];
}


#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingPendingQueries
{
    return [self savedKeys];
}

- (instancetype)init
{
    if((self = [super init])) {
        _dbLock = OS_SPINLOCK_INIT;
        _UUID = [NSUUID UUID];
    }
    return self;
}

- (instancetype)initWithDatabase:(DB *)aDB result:(DBResult *)result
{
    NSParameterAssert(aDB);

    if((self = [self init])) {
        NSArray *columns = result.columns;
        for(NSUInteger i = 0; i < columns.count; ++i) {
            id value = [result valueOfColumnAtIndex:i];
            if([value isKindOfClass:[NSData class]]) {
                DBPropertyAttributes *attrs = DBAttributesForProperty(self.class,
                                                                      class_getProperty(self.class, [columns[i] UTF8String]));
                if(attrs && DBPropertyConformsToProtocol(attrs, @protocol(NSCoding)))
                    value = [NSKeyedUnarchiver unarchiveObjectWithData:value];
                free(attrs);
            }

            [self setValue:(value == [NSNull null]) ? nil : value
                    forKey:columns[i]];
        }
        _savedUUID = _UUID;

        self.database = aDB;
    }
    return self;
}

- (DB *)database
{
    OSSpinLockLock(&_dbLock);
    DB *db = _database;
    OSSpinLockUnlock(&_dbLock);
    return db;
}
- (void)setDatabase:(DB *)database
{
    OSSpinLockLock(&_dbLock);
    if(database != _database) {
        _database = database;
        if(_database) {
            _pendingQueries = [DBOrderedDictionary new];
            // This is to coerce KVC into calling didChangeValueForKey:
            // We don't actually take any action when pendingQueries changes
            [self addObserver:self
                   forKeyPath:@"pendingQueries"
                      options:0
                      context:NULL];
        } else {
            _pendingQueries = nil;
            _savedUUID = nil;
            [self removeObserver:self forKeyPath:@"pendingQueries"];
        }
    }
    OSSpinLockUnlock(&_dbLock);
}

- (void)didChangeValueForKey:(NSString *)key
{
    if(_database && _pendingQueries && [self.class.savedKeys containsObject:key]) {
        [self willChangeValueForKey:@"hasChanges"];
        _pendingQueries[key] = [self saveQueryForKey:key];
        [self.database registerDirtyObject:self];
        [self didChangeValueForKey:@"hasChanges"];
    }
    [super didChangeValueForKey:key];
}

- (void)dealloc
{
    self.database = nil; // Un-register KVO
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // No action
}

- (id)valueForKey:(NSString *)key
{
    return [super valueForKey:key];
}
- (void)setValue:(id)value forKey:(NSString *)key
{
    [super setValue:value forKey:key];
}
- (void)setNilValueForKey:(NSString * const)aKey
{
    [self setValue:@0 forKey:aKey];
}

- (DBWriteQuery *)saveQueryForKey:(NSString *)key
{
    SEL selector = DBCapitalizedSelector(@"saveQueryFor", key);
    if([self respondsToSelector:selector]) {
        id (*imp)(id,SEL) = (void*)[self methodForSelector:selector];
        return imp(self, selector);
    }
    else if(![self.database[self.class.tableName].columnNames containsObject:key]) {
        DBPropertyAttributes *attrs = DBAttributesForProperty(self.class, class_getProperty(self.class, [key UTF8String]));
        Class relatedClass;
        BOOL pluralRelationship;
        if(![self.class _attributeIsRelationship:attrs isPlural:&pluralRelationship relatedClass:&relatedClass]) {
            free(attrs);
            return nil;
        }
        free(attrs);

        id relatedObject = [self valueForKey:key];
        if(relatedObject) {
            NSString *ownerKey = [self.class.tableName db_singularizedString];
            DBTable *joinTable = self.database[[self.class joinTableNameForKey:key]];
            if(!pluralRelationship)
                return [[joinTable insert:@{
                    ownerKey: _UUID,
                    key: [relatedObject UUID]
                    }] or:DBInsertFallbackReplace];
            else if([relatedObject count] > 0) {
                NSMutableArray *queries = [NSMutableArray new];
                [queries addObject:[[joinTable delete]
                                    where:@"(%K = %@) AND (NOT %K IN %@)",
                                          ownerKey, _UUID,
                                          key, [relatedObject valueForKey:kDBUUIDKey]]];
                for(DBModel *object in relatedObject) {
                    [queries addObject:[joinTable insert:@{ ownerKey: _UUID,
                                                            key: object.UUID }]];
                    
                }
                // Since saves are always executed within a transaction anyway,
                // we can safely not use DBTransactionQuery
                return [DBBatchQuery queryWithQueries:queries];
            }
        }
        return [[self.database[[self.class joinTableNameForKey:key]] delete]
                where:@"%K=%@", [self.class.tableName db_singularizedString], _UUID];
    } else if(!self.saved)
        return [self.query insert:@{ key: [self valueForKey:key] ?: [NSNull null] }];
    else
        return [self.query update:@{ key: [self valueForKey:key] ?: [NSNull null] }];
}

- (BOOL)_executePendingQueriesReplacingExisting:(BOOL const)replaceExisting error:(NSError **)outErr
{
    NSAssert(_database, @"Tried to save object not in a database");

    if(!_savedUUID) {
        for(NSString *key in [self.class savedKeys]) {
            if(!_pendingQueries[key])
                _pendingQueries[key] = [self saveQueryForKey:key];
        }
    }
    if(_pendingQueries.count == 0)
        return YES;
    
    for(__strong DBWriteQuery *query in [DBQuery combineQueries:_pendingQueries.allValues]) {
        if(replaceExisting && [query isKindOfClass:[DBInsertQuery class]])
            query = [(DBInsertQuery *)query or:DBInsertFallbackReplace];
        if(![query execute:outErr])
            return NO;
    }

    _savedUUID = self.UUID;
    [self willChangeValueForKey:@"hasChanges"];
    [_pendingQueries removeAllObjects];
    [self didChangeValueForKey:@"hasChanges"];
    return YES;
}

- (BOOL)isSaved
{
    return _savedUUID != nil;
}
- (BOOL)hasChanges
{
    return _pendingQueries.count > 0;
}

#pragma mark -

- (DBQuery *)query
{
    return [_database[self.class.tableName] where:@"%K = %@", kDBUUIDKey, _savedUUID ?: _UUID];
}
- (DBSelectQuery *)selectQueryForKey:(NSString *)key
{
    NSParameterAssert(key);
    
    DBPropertyAttributes *attrs = DBAttributesForProperty(self.class, class_getProperty(self.class, [key UTF8String]));
    BOOL isPlural;
    Class relatedKlass;
    if([self.class _attributeIsRelationship:attrs isPlural:&isPlural relatedClass:&relatedKlass])
        return [self _selectQueryForRelatedKey:key class:relatedKlass isPlural:isPlural];
    else
        return [self.query select:@[key]];
}
- (DBSelectQuery *)_selectQueryForRelatedKey:(NSString *)key class:(Class)relatedKlass isPlural:(BOOL)isPlural
{
    NSString *joinTableName = [self.class joinTableNameForKey:key];
    DB *db = self.database;
    return [[[db[relatedKlass.tableName]
             select:@[[NSString stringWithFormat:@"%@.*", relatedKlass.tableName]]]
            distinct:YES]
            innerJoin:db[joinTableName] on:@"%K.%K=%@", joinTableName, [self.class.tableName db_singularizedString], _UUID];
}

- (id)valueForKey:(NSString *)key matchingPredicate:(NSPredicate *)predicate
{
    DBPropertyAttributes * const keyAttrs = DBAttributesForProperty(self.class, class_getProperty(self.class, key.UTF8String));
    NSAssert(keyAttrs != nil, @"%@ is not KVC compliant for '%@'", self.class, key);
    
    if(!predicate)
        return [self valueForKey:key];
    
    id result;
    Class relatedClass;
    BOOL isPlural;
    if([self.class _attributeIsRelationship:keyAttrs isPlural:&isPlural relatedClass:&relatedClass]) {
        if(!isPlural)
            result = object_getIvar(self, keyAttrs->ivar)
                  ?: [[self.database[relatedClass.tableName] select] withPredicate:predicate];
        else {
            result = object_getIvar(self, keyAttrs->ivar);
            if([result isKindOfClass:[NSSet class]])
                return [result filteredSetUsingPredicate:predicate];
            else {
                DBSelectQuery *query = [self _selectQueryForRelatedKey:key class:relatedClass isPlural:isPlural];
                query = query.where
                      ? [query withPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:@[query.where, predicate]]]
                      : [query withPredicate:predicate];
                return [NSSet setWithArray:[query execute]];
            }
        }
    } else {
        result = object_getIvar(self, keyAttrs->ivar);
        if(![predicate evaluateWithObject:result])
            result = nil;
    }
    free(keyAttrs);
    return result;
}

#pragma mark -

+ (NSString *)tableName
{
    static void *tableNameKey = &tableNameKey;
    NSString *tableName = objc_getAssociatedObject(self, tableNameKey);
    if(!tableName) {
        NSMutableString *builder = [NSStringFromClass(self) mutableCopy];
        NSUInteger dotLocation = [builder rangeOfString:@"."].location;
        if(dotLocation != NSNotFound)
            [builder deleteCharactersInRange:(NSRange) { 0, dotLocation+1 }];

        NSRange prefixRange = [builder rangeOfString:@"[A-Z]*" options:NSRegularExpressionSearch];
        if(prefixRange.location != 0 || NSMaxRange(prefixRange) == builder.length)
            return nil;
        else
            [builder deleteCharactersInRange:(NSRange) { 0, prefixRange.length-1 }];

        tableName = [[builder db_stringByDecapitalizingFirstLetter] db_pluralizedString];
        objc_setAssociatedObject(self, tableNameKey, tableName, OBJC_ASSOCIATION_RETAIN);
    }
    return tableName;
}

#pragma mark -

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@:%p> (stored id: %@) {\n",
                                                                     self.class, self, self.savedUUID.UUIDString];
    for(NSString *key in self.class.savedKeys) {
        [description appendFormat:@"%@ = %@\n", key, [self valueForKey:key]];
    }
    [description appendString:@"}"];
    return description;
}

- (NSUInteger)hash
{
    return [_UUID hash];
}
- (BOOL)isEqual:(id)anObject
{
    return self == anObject
        || ([anObject isMemberOfClass:self.class]
            && self.database == [anObject database]
            && [_UUID isEqual:[anObject UUID]]);
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    DBModel *copy = [self.class new];
    for(NSString *column in self.class.savedKeys) {
        if(![column isEqualToString:kDBUUIDKey])
            [copy setValue:[self valueForKey:column] forKey:column];
    }
    return copy;
}

@end
