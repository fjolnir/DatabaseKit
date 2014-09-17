#import "DBModel+Private.h"
#import "DBTable.h"
#import "DBQuery.h"
#import "Debug.h"
#import "Utilities/NSString+DBAdditions.h"
#import <objc/runtime.h>
#include <unistd.h>

static NSString *classPrefix = nil;

@implementation DBModel

+ (void)setClassPrefix:(NSString *)aPrefix
{
    classPrefix = aPrefix;
}
+ (NSString *)classPrefix
{
    return classPrefix ? classPrefix : @"";
}

+ (char)typeForKey:(NSString *)key class:(Class *)outClass
{
    objc_property_t const property = class_getProperty([self class], [key UTF8String]);
    NSAssert(property, @"Key %@ not found on %@", key, [self class]);

    char * const type = property_copyAttributeValue(property, "T");
    NSAssert(type, @"Unable to get type for key %@", key);

    if(*type == _C_ID && outClass && type[1] == '"') {
        NSScanner * const scanner = [NSScanner scannerWithString:[NSString stringWithUTF8String:type+2]];
        NSString *className;
        if([scanner scanUpToString:@"\"" intoString:&className])
            *outClass = NSClassFromString(className);
    }
    char const result = *type;
    free(type);
    return result;
}

#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingDirtyKeys
{
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList(self, &propertyCount);

    NSMutableSet *keyPaths = [[self superclass] instancesRespondToSelector:_cmd]
        ? [[super keyPathsForValuesAffectingValueForKey:@"dirtyKeys"] mutableCopy]
        : [NSMutableSet setWithCapacity:propertyCount];

    for(int i = 0; i < propertyCount; ++i) {
        const char * const name = property_getName(properties[i]);
        // If super also has it we're not interested
        if(class_getProperty([self superclass], name))
            continue;
        [keyPaths addObject:[NSString stringWithUTF8String:name]];
    }
    [keyPaths addObject:kDBIdentifierColumn];
    free(properties);
    return keyPaths;
}

- (instancetype)init
{
    if((self = [super init]))
        // This is to coerce KVC into calling didChangeValueForKey:
        // We don't actually take any action when dirtyKeys changes
        [self addObserver:self
               forKeyPath:@"dirtyKeys"
                  options:0
                  context:NULL];
    return self;
}

- (id)initWithDatabase:(DB *)aDB
{
    NSParameterAssert(aDB);
    if(!(self = [self init]))
        return nil;

    self.table      = aDB[[[self class] tableName]];
    _dirtyKeys   = [NSMutableSet new];

    return self;
}

- (void)didChangeValueForKey:(NSString *)key
{
    if([self.table.columns containsObject:key])
        [_dirtyKeys addObject:key];
    [super didChangeValueForKey:key];
}


- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"dirtyKeys"];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // No action
}

- (BOOL)save:(NSError **)outErr
{
    if([_dirtyKeys count] > 0) {
        NSDictionary *changedValues = [self dictionaryWithValuesForKeys:[_dirtyKeys allObjects]];
        [_dirtyKeys removeAllObjects];

        if([changedValues.allKeys containsObject:kDBIdentifierColumn])
            return [[[[self query] insert:changedValues] or:DBInsertFallbackReplace] execute:outErr] != nil;
        else
            return [[[self query] update:changedValues] execute:outErr] != nil;
    }
    return YES;
}

- (BOOL)destroy
{
    @try {
        [[[_table delete] where:@{ kDBIdentifierColumn: _identifier }] execute];
        return YES;
    }
    @catch(NSException *e) {
        DBLog(@"Error deleting record with id %ld, exception: %@", (unsigned long)self.identifier, e);
        return NO;
    }
}

- (void)_clearDirtyKeys
{
    [_dirtyKeys removeAllObjects];
}

#pragma mark -

- (DBQuery *)query
{
    return [_table where:@{ kDBIdentifierColumn: _identifier }];
}

- (void)setNilValueForKey:(NSString * const)aKey
{
    [self setValue:@0 forKey:aKey];
}

#pragma mark -

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

#pragma mark -

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@:%p> (stored id: %@) {\n", [self className], self, [self identifier]];
    for(NSString *column in self.table.columns) {
        [description appendFormat:@"%@ = %@\n", column, [self valueForKey:column]];
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
    for(NSString *column in self.table.columns) {
        [copy setValue:[self valueForKey:column] forKey:column];
    }
    return copy;
}

@end
