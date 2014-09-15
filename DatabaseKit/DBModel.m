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
#pragma mark Delayed writing

- (void)didChangeValueForKey:(NSString *)key
{
    if([self.table.columns containsObject:key])
        [_dirtyKeys addObject:key];
    [super didChangeValueForKey:key];
}

- (void)save
{
    if([_dirtyKeys count] > 0) {
        [[self query] update:[self dictionaryWithValuesForKeys:[_dirtyKeys allObjects]]];
        [_dirtyKeys removeAllObjects];
    }
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

#pragma mark - Entry retrieval

- (id)initWithDatabase:(DB *)aDB
{
    NSParameterAssert(aDB);
    if(!(self = [self init]))
        return nil;

    self.table      = aDB[[[self class] tableName]];
    _dirtyKeys   = [NSMutableSet new];

    return self;
}

- (DBQuery *)query
{
    return [_table where:@{ kDBIdentifierColumn: _identifier }];
}

#pragma mark -
#pragma mark Accessors

- (void)setNilValueForKey:(NSString * const)aKey
{
    [self setValue:@0 forKey:aKey];
}

#pragma mark -
#pragma mark Database interface

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

@end
