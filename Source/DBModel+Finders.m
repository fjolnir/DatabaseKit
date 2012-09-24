//
//  DBModel+Finders.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 14.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import "DBModel+Finders.h"
#import "DBTable.h"
#import "DBQuery.h"

@implementation DBModel (Finders)
+ (NSArray *)find:(DBFindSpecification)idOrSpecification
{
    return [self find:idOrSpecification
           connection:[self defaultConnection]];
}
+ (NSArray *)find:(DBFindSpecification)idOrSpecification connection:(id<DBConnection>)connection
{
    return [self find:idOrSpecification
               filter:nil
                 join:nil
                order:DBOrderAscending
                limit:0
           connection:connection];
}

+ (NSArray *)find:(DBFindSpecification)idOrSpecification
           filter:(id)filter
             join:(NSString *)joinSQL
            order:(NSString *)order
            limit:(NSUInteger)limit
{
    return [self find:idOrSpecification
               filter:filter
                 join:joinSQL
                order:order
                limit:limit
           connection:[self defaultConnection]];
}
+ (NSArray *)find:(DBFindSpecification)idOrSpecification
           filter:(id)filter
             join:(NSString *)joinSQL
            order:(NSString *)order
            limit:(NSUInteger)limit
       connection:(id<DBConnection>)aConnection
{
    NSArray *ids = [self findIds:idOrSpecification
                          filter:filter
                            join:joinSQL
                           order:order
                           limit:limit
                      connection:[self defaultConnection]];

    NSMutableArray *models = [NSMutableArray array];
    for(NSDictionary *match in ids)
    {
        NSUInteger id = [match[@"id"] unsignedIntValue];
        [models addObject:[[self alloc] initWithConnection:aConnection id:id]];
    }
    return models;
}

+ (NSArray *)findIds:(DBFindSpecification)idOrSpecification
              filter:(id)filter
                join:(NSString *)joinSQL
               order:(NSString *)order
               limit:(NSUInteger)limit
          connection:(id<DBConnection>)aConnection
{
    DBTable *table = [DBTable withConnection:aConnection name:[self tableName]];
    DBQuery *q = [[table select:@"id"] limit:@(limit)];
    if(idOrSpecification >= 0)
        q = [q where:@{ @"id": @(idOrSpecification) }];
    if(filter)
        [q appendWhere:filter];
    return [q execute];

#if 0
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSMutableString *query = [NSMutableString stringWithFormat:@"SELECT id FROM %@", [self tableName]];
//    if(joinSQL)
//        [query appendFormat:@" %@", joinSQL];

    if(idOrSpecification >= 0) { // It's an actual id
        [query appendString:@" WHERE id=:id"];
        [params setObject:[NSNumber numberWithInteger:idOrSpecification] forKey:@"id"];
    }
    
    if([filter isKindOfClass:[NSDictionary class]] || [filter isKindOfClass:[NSMapTable class]]) {
        [query appendString:idOrSpecification >= 0 ? @" AND" : @" WHERE"];
        NSDictionary *filterPairs = filter;
        int i = 0;
        for(NSString *field in [filterPairs allKeys]) {
            [query appendFormat:@"%@ %@=:%@", i++ == 0 ? @"" : @" AND", field, field];
            [params setObject:[filterPairs objectForKey:field] forKey:field];
        }
    } else if(filter) {
        [query appendString:idOrSpecification >= 0 ? @" AND " : @" WHERE "];
        [query appendString:filter];
    }

    return [aConnection executeQuery:[DBQuery queryWithString:query
                                                   parameters:params
                                                        limit:idOrSpecification == DBFindFirst ? 1 : limit
                                                        order:order]];
#endif
}


#pragma mark -
#pragma mark convenience accessors
+ (NSArray *)findAll
{
    return [self find:DBFindAll];
}

+ (id)first
{
    return [self first:nil];
}

+ (id)first:(NSString *)filter
{
    NSArray *result = [self find:DBFindFirst filter:filter join:nil order:DBOrderAscending limit:1];
    return [result count] > 0 ? result[0] : nil;
}

+ (id)last
{
    NSArray *result = [self find:DBFindFirst filter:nil join:nil order:DBOrderDescending limit:1];
    return [result count] > 0 ? result[0] : nil;
}
@end
