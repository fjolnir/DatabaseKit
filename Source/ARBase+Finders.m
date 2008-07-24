//
//  ARBase+Finders.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 14.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import "ARBase+Finders.h"


@implementation ARBase (Finders)
+ (NSArray *)find:(ARFindSpecification)idOrSpecification 
{
  return [self find:idOrSpecification
         connection:[self defaultConnection]];
}
+ (NSArray *)find:(ARFindSpecification)idOrSpecification connection:(id<ARConnection>)connection
{
  return [self find:idOrSpecification
             filter:nil 
              order:nil
              limit:0
         connection:connection];
}

+ (NSArray *)find:(ARFindSpecification)idOrSpecification 
           filter:(NSString *)whereSQL 
            order:(NSString *)orderSQL
            limit:(NSUInteger)limit
{
  return [self find:idOrSpecification
             filter:whereSQL 
              order:orderSQL
              limit:limit
         connection:[self defaultConnection]];
}
+ (NSArray *)find:(ARFindSpecification)idOrSpecification
           filter:(NSString *)whereSQL 
            order:(NSString *)orderSQL 
            limit:(NSUInteger)limit
       connection:(id<ARConnection>)aConnection
{
  NSMutableString *query = [NSMutableString stringWithFormat:@"SELECT id FROM %@", [self tableName]];
  switch(idOrSpecification)
  {
    case ARFindFirst:
      [query appendString:@" LIMIT 1"];
      break;
    case ARFindAll:
      break;
    default:
      [query appendString:@" WHERE id=:id"];
      break;
  }
  if(idOrSpecification == ARFindFirst || idOrSpecification == ARFindAll)
  {
    if(whereSQL != nil)
      [query appendFormat:@" WHERE %@", whereSQL];
    if(orderSQL != nil)
      [query appendFormat:@" ORDER %@", orderSQL];
  }
  else
  {
    if(whereSQL != nil)
      [query appendFormat:@" AND %@", whereSQL];
    if(orderSQL != nil)
      [query appendFormat:@" ORDER %@", orderSQL];
  }
  if(limit > 0)
    [query appendFormat:@" LIMIT %d", limit];
  
  NSArray *matches = [aConnection executeSQL:query
                               substitutions:[NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInteger:idOrSpecification], @"id", nil]];
  
  NSMutableArray *models = [NSMutableArray array];
  for(NSDictionary *match in matches)
  {
    NSUInteger id = [[match objectForKey:@"id"] unsignedIntValue];
    [models addObject:[[[self alloc] initWithConnection:aConnection id:id] autorelease]];
  }
  return models;
}

#pragma mark -
#pragma mark convenience accessors
+ (NSArray *)findAll
{
  return [self find:ARFindAll];
}
@end
