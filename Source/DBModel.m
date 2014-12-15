#import "DBModel+Private.h"
#import "DB+Private.h"
#import "DBSelectQuery.h"
#import "DBInsertQuery.h"
#import "DBDeleteQuery.h"
#import "DBTable.h"
#import "DBQuery.h"
#import "Debug.h"
#import "NSString+DBAdditions.h"
#import "DBIntrospection.h"
#import "DBOrderedDictionary.h"
#import <objc/runtime.h>
#import <unistd.h>


@implementation DBModel {
    DBOrderedDictionary *_pendingQueries;
}
@dynamic inserted, hasChanges;

+ (NSSet *)savedKeys
{
    unsigned int propertyCount;
    objc_property_t * properties = class_copyPropertyList(self, &propertyCount);
    if(properties) {
        NSSet *excludedKeys = [self excludedKeys];
        NSMutableSet *result = [NSMutableSet setWithObject:kDBIdentifierColumn];
        for(NSUInteger i = 0; i < propertyCount; ++i) {
            NSString *key = @(property_getName(properties[i]));
            char * const getterName = property_copyAttributeValue(properties[i], "G")
                                   ?: strdup([key UTF8String]);
            Class klass;
            char encoding = [self typeForKey:key class:&klass];
            if(![[DBModel superclass] instancesRespondToSelector:sel_registerName(getterName)] &&
               ![excludedKeys containsObject:key] &&
               (encoding != _C_ID || [klass conformsToProtocol:@protocol(NSCoding)]))
                [result addObject:key];
            free(getterName);
        }
        return result;
    } else
        return nil;
}

+ (NSSet *)excludedKeys
{
    return nil;
}

+ (NSArray *)indices
{
    return nil;
}

+ (char)typeForKey:(NSString *)key class:(Class *)outClass
{
    objc_property_t const property = class_getProperty([self class], [key UTF8String]);
    NSAssert(property, @"Key %@ not found on %@", key, [self class]);

    char * const type = property_copyAttributeValue(property, "T");
    NSAssert(type, @"Unable to get type for key %@", key);

    if(outClass && type[0] == _C_ID && type[1] == '"') {
        NSScanner * const scanner = [NSScanner scannerWithString:@(type+2)];
        NSString *className;
        if([scanner scanUpToString:@"\"" intoString:&className])
            *outClass = NSClassFromString(className);
    }
    char const result = *type;
    free(type);
    return result;
}

+ (NSArray *)constraintsForKey:(NSString *)key
{
    // Check if we respond to the selector `constraintsFor<Key>`
    SEL selector = DBCapitalizedSelector(@"constraintsFor", key);
    if([self respondsToSelector:selector]) {
        id (*imp)(id,SEL) = (void*)[self methodForSelector:selector];
        return imp(self, selector);
    } else
        return nil;
}

+ (NSArray *)constraintsForIdentifier
{
    return @[[DBPrimaryKeyConstraint primaryKeyConstraintWithOrder:DBOrderAscending
                                                     autoIncrement:NO
                                                        onConflict:DBConflictActionFail],
             [DBNotNullConstraint new]];
}


#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingPendingQueries
{
    NSMutableSet *keyPaths = [NSMutableSet setWithObject:kDBIdentifierColumn];

    Class klass = self;
    do {
        unsigned int propertyCount;
        objc_property_t *properties = class_copyPropertyList(klass, &propertyCount);
        for(int i = 0; i < propertyCount; ++i) {
            [keyPaths addObject:@(property_getName(properties[i]))];
        }
        [keyPaths addObject:kDBIdentifierColumn];
        free(properties);
    } while((klass = [klass superclass]) != [DBModel class]);
    
    return keyPaths;
}

- (instancetype)init
{
    if((self = [super init]))
        // This is to coerce KVC into calling didChangeValueForKey:
        // We don't actually take any action when pendingQueries changes
        [self addObserver:self
               forKeyPath:@"pendingQueries"
                  options:0
                  context:NULL];
    return self;
}

- (instancetype)initWithDatabase:(DB *)aDB result:(DBResult *)result
{
    NSParameterAssert(aDB);
    if((self = [self init])) {
        _table     = aDB[[[self class] tableName]];
        _pendingQueries = [DBOrderedDictionary new];

        NSArray *columns = result.columns;
        for(NSUInteger i = 0; i < [columns count]; ++i) {
            id value = [result valueOfColumnAtIndex:i];
            if([value isKindOfClass:[NSData class]]) {
                Class klass;
                char encoding = [[self class] typeForKey:columns[i] class:&klass];
                if(encoding == _C_ID && ![klass isSubclassOfClass:[NSData class]])
                    value = [NSKeyedUnarchiver unarchiveObjectWithData:value];
            }
            [self setValue:(value == [NSNull null]) ? nil : value
                    forKey:columns[i]];
        }
        _savedIdentifier = _identifier;
    }
    return self;
}

- (instancetype)initWithDatabase:(DB *)aDB
{
    DBModel *model = [self initWithDatabase:aDB result:nil];
    model.identifier = [[NSUUID UUID] UUIDString];
    return model;
}

- (void)didChangeValueForKey:(NSString *)key
{
    if(_pendingQueries && [[[self class] savedKeys] containsObject:key]) {
        [self willChangeValueForKey:@"hasChanges"];
        _pendingQueries[key] = [self saveQueryForKey:key];
        [self didChangeValueForKey:@"hasChanges"];
        [self.table.database registerDirtyObject:self];
    }
    [super didChangeValueForKey:key];
}


- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"pendingQueries"];
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
    if(!self.inserted)
        return [self.query insert:@{ key: [self valueForKey:key] ?: [NSNull null] }];
    else
        return [self.query update:@{ key: [self valueForKey:key] ?: [NSNull null] }];
}

- (BOOL)_save:(NSError **)outErr
{
    DBConnection *connection = self.table.database.connection;
    BOOL saved = [connection executeWriteQueriesInTransaction:[DBQuery combineQueries:_pendingQueries.allValues]
                                                        error:outErr];
    if(saved) {
        _savedIdentifier = self.identifier;
        [self willChangeValueForKey:@"hasChanges"];
        [_pendingQueries removeAllObjects];
        [self didChangeValueForKey:@"hasChanges"];
        return YES;
    } else
        return NO;
}

- (BOOL)destroy
{
    if(self.isInserted) {
        @try {
            return [[[self query] delete] execute];
        }
        @catch(NSException *e) {
            DBLog(@"Error deleting record with id %ld, exception: %@", (unsigned long)self.identifier, e);
            return NO;
        }
    } else
        return NO;
}

- (BOOL)isInserted
{
    return _savedIdentifier != nil;
}
- (BOOL)hasChanges
{
    return _pendingQueries.count > 0;
}

#pragma mark -

- (DBQuery *)query
{
    return [_table where:@"%K = %@", kDBIdentifierColumn, _savedIdentifier ?: _identifier];
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
                                                                     [self class], self, self.savedIdentifier];
    for(NSString *key in [[self class] savedKeys]) {
        [description appendFormat:@"%@ = %@\n", key, [self valueForKey:key]];
    }
    [description appendString:@"}"];
    return description;
}

- (NSUInteger)hash
{
    return [_table hash] ^ [_identifier hash];
}
- (BOOL)isEqual:(id)anObject
{
    return [anObject isMemberOfClass:[self class]]
        && [[anObject identifier] isEqual:[self identifier]];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    DBModel *copy = [[[self class] alloc] initWithDatabase:self.table.database];
    for(NSString *column in [[self class] savedKeys]) {
        if(![column isEqualToString:kDBIdentifierColumn])
            [copy setValue:[self valueForKey:column] forKey:column];
    }
    return copy;
}

@end
