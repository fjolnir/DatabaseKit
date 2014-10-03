#import "DBModel+Private.h"
#import "DBTable.h"
#import "DBQuery.h"
#import "Debug.h"
#import "Utilities/NSString+DBAdditions.h"
#import <objc/runtime.h>
#include <unistd.h>

static NSString *classPrefix = nil;

@implementation DBModel
@dynamic inserted;

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
    NSMutableSet *keyPaths = [NSMutableSet new];

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

- (BOOL)save
{
    return [self save:NULL];
}
- (BOOL)save:(NSError **)outErr
{
    if([_dirtyKeys count] > 0) {
        NSDictionary *changedValues = [self dictionaryWithValuesForKeys:[_dirtyKeys allObjects]];
        [_dirtyKeys removeAllObjects];

        DBWriteQuery * const query = !_savedIdentifier
            ? [[[self query] insert:changedValues] or:DBInsertFallbackReplace]
            : [[self query] update:changedValues];
        if([query execute:outErr]) {
            _savedIdentifier = self.identifier;
            return YES;
        } else
            return NO;
    }
    return YES;
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

- (void)_clearDirtyKeys
{
    [_dirtyKeys removeAllObjects];
}

#pragma mark -

- (DBQuery *)query
{
    return [_table where:@"%K = %@", kDBIdentifierColumn, _savedIdentifier ?: _identifier];
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
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@:%p> (stored id: %@) {\n", [self className], self, self.savedIdentifier];
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
        if(![column isEqualToString:kDBIdentifierColumn])
            [copy setValue:[self valueForKey:column] forKey:column];
    }
    return copy;
}

@end
