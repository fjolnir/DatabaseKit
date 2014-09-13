#import "DBModel.h"
#import "DBTable.h"
#import "DBQuery.h"
#import "DBModel+Private.h"
#import "Debug.h"
#import "Utilities/NSString+DBAdditions.h"
#import <objc/runtime.h>
#include <unistd.h>

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
    }
    return NO;
}

#pragma mark - Entry retrieval

- (id)initWithTable:(DBTable *)aTable identifier:(NSString *)aIdentifier
{
    if(!(self = [self init]))
        return nil;
    NSParameterAssert(aTable && aIdentifier > 0);
    self.table      = aTable;
    self.identifier = aIdentifier;

    _dirtyKeys   = [NSMutableSet new];

    return self;
}

- (DBQuery *)query
{
    return [_table where:@{ kDBIdentifierColumn: _identifier }];
}

#pragma mark -
#pragma mark Accessors

- (id)objectForKeyedSubscript:(id)key
{
    return [self valueForKey:key];
}
- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key
{
    NSParameterAssert([(NSObject*)key isKindOfClass:[NSString class]]);
    [self setValue:obj forKey:(NSString *)key];
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
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@:%p> (stored id: %ld) {\n", [self className], self, (unsigned long)[self identifier]];
    for(NSString *column in self.table.columns) {
        if(![column isEqualToString:kDBIdentifierColumn] && ![column hasSuffix:@"Identifier"])
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
