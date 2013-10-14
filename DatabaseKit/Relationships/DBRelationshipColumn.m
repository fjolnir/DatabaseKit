#import "DBRelationshipColumn.h"
#import "../DBModelPrivate.h"
#import "../DBTable.h"
#import "../DBQuery.h"
#import "../Debug.h"

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
    // If the cache is enabled, we just fetch the entire row
    BOOL cache = [DBModel enableCache];
    DBQuery *query = cache ? [self.record.table select] : [self.record.table select:key];
    NSArray *result = [[query where:@{ @"id": @(self.record.databaseId) }] execute];
    if([result count] < 1) {
        DBDebugLog(@"Couldn't get result: %@", query);
        return nil;
    }
    NSDictionary *row = result[0];
    if(cache) {
        for(id key in row) {
            [self.record.readCache setObject:row[key] forKey:key];
        }
    }
    return row[key];
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
