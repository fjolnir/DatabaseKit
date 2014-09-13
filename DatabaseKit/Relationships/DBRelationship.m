//
//  DBRelationship.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 30.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import "DBRelationship.h"
#import "../DBModel.h"

@interface DBRelationship ()
@property(readwrite, strong) NSString *name, *className;
@property(readwrite, weak) DBModel *record;
@end

@implementation DBRelationship

+ (id)relationshipWithName:(NSString *)aName className:(NSString *)aClassName
{
    return [[self alloc] initWithName:aName className:aClassName record:nil];
}
+ (id)relationshipWithName:(NSString *)aName
{
    return [[self alloc] initWithName:aName className:nil record:nil];
}
- (id)initWithName:(NSString *)aName className:(NSString *)aClassName record:(DBModel *)aRecord
{
    if(!(self = [super init]))
        return nil;
    self.name      = aName;
    self.className = aClassName;
    self.record    = aRecord;
    return self;
}

- (BOOL)respondsToKey:(NSString *)key supportsAdding:(BOOL *)supportsAddingRet
{
    if(supportsAddingRet != NULL)
        *supportsAddingRet = NO;
    return NO;
}
- (BOOL)respondsToKey:(NSString *)key
{
    return [self respondsToKey:key supportsAdding:NULL];
}
- (id)retrieveRecordForKey:(NSString *)key
{
    return [self retrieveRecordForKey:key filter:nil order:nil by:nil limit:nil];
}
- (id)retrieveRecordForKey:(NSString *)key
                    filter:(id)conditions
                     order:(NSString *)order
                        by:(id)orderByFields
                     limit:(NSNumber *)limit
{
    [NSException raise:@"Unused method" format:@"You shouldn't be using DBRelationship directly!"];
    return nil;
}
- (void)sendRecord:(id)record forKey:(NSString *)key
{
    return;
}
- (void)addRecord:(id)record forKey:(NSString *)key
{
    return;
}
- (void)removeRecord:(id)record forKey:(NSString *)key
{
    return;
}

#pragma mark -
#pragma mark Copying
- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithName:_name className:_className record:_record];
}
- (id)copyUsingRecord:(DBModel *)record
{
    DBRelationship *ret = [self copy];
    ret.record = record;
    return ret;
}

#pragma mark -
#pragma mark Cosmetics
- (NSString *)description
{
    return [NSString stringWithFormat:@"{ %@ Name: %@ }", [super description], self.name];
}
@end

@implementation DBModel (Relationships)
- (NSArray *)relationshipsOfType:(NSString *)type
{
    NSMutableArray *ret = [NSMutableArray array];
    for(DBRelationship *relationship in self.relationships) {
        if([[[relationship class] className] isEqualToString:type])
            [ret addObject:relationship];
    }
    return ret;
}
@end
