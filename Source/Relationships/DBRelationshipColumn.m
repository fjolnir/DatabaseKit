#import "DBRelationshipColumn.h"
#import "DBBasePrivate.h"
#import "DBTable.h"
#import "DBQuery.h"

@implementation DBRelationshipColumn
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
    NSArray *query = [[[self.record.table select:key] where:@{ @"id": @(self.record.databaseId) }] execute];
    if([query count] < 1)
    {
        DBDebugLog(@"Couldn't get result: %@", query);
        return nil;
    }
    return query[0][key];
}
- (id)retrieveRecordForKey:(NSString *)key
                    filter:(id)conditions
                     order:(NSString *)order
                        by:(id)orderByFields
                     limit:(NSNumber *)limit
{
    return [self retrieveRecordForKey:key];
}
- (void)sendRecord:(id)aRecord forKey:(NSString *)key
{
    if(![self respondsToKey:key])
        return;
    [[[self.record.table update:@{ key: aRecord }] where:@{ @"id": @(self.record.databaseId) }] execute];
}

@end
