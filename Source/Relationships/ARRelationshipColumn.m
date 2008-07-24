//
//  ARRelationshipColumn.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 9/12/07.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import "ARRelationshipColumn.h"
#import "ARBasePrivate.h"

@implementation ARRelationshipColumn
#pragma mark Key parser
#pragma mark -
- (BOOL)respondsToKey:(NSString *)key supportsAdding:(BOOL *)supportsAddingRet
{
    if(supportsAddingRet != NULL)
        *supportsAddingRet = NO;
    if([[self.record columns] containsObject:key])
        return YES;
    return NO;
}
#pragma mark -
- (id)retrieveRecordForKey:(NSString *)key
{
    if(![self respondsToKey:key])
        return nil;
    NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE id = :id", key, [[self.record class] tableName]];
    NSArray *result = [self.record.connection executeSQL:query 
                                           substitutions:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [NSNumber numberWithInt:self.record.databaseId], @"id", nil]];
    if([result count] < 1)
    {
        ARDebugLog(@"Couldn't get result: %@", result);
        return nil;
    }
    return [[result objectAtIndex:0] objectForKey:key];
}
- (id)retrieveRecordForKey:(NSString *)key 
										filter:(NSString *)whereSQL 
										 order:(NSString *)orderSQL
										 limit:(NSUInteger)limit
{
	return [self retrieveRecordForKey:key];
}
- (void)sendRecord:(id)aRecord forKey:(NSString *)key
{
    if(![self respondsToKey:key])
        return;
    NSString *query = [NSString stringWithFormat:@"UPDATE %@ SET %@=:value WHERE id = :id", [[self.record class] tableName], key];
    [self.record.connection executeSQL:query
                         substitutions:[NSDictionary dictionaryWithObjectsAndKeys:aRecord, @"value",
                                        [NSNumber numberWithInt:self.record.databaseId], @"id", nil]];
}

@end
