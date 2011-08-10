//
//  ARBase+Finders.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 14.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
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
							 join:nil
              order:nil
              limit:0
         connection:connection];
}

+ (NSArray *)find:(ARFindSpecification)idOrSpecification 
           filter:(NSString *)whereSQL 
						 join:(NSString *)joinSQL
            order:(NSString *)orderSQL
            limit:(NSUInteger)limit
{
  return [self find:idOrSpecification
             filter:whereSQL 
							 join:joinSQL
              order:orderSQL
              limit:limit
         connection:[self defaultConnection]];
}
+ (NSArray *)find:(ARFindSpecification)idOrSpecification
           filter:(NSString *)whereSQL 
						 join:(NSString *)joinSQL
            order:(NSString *)orderSQL 
            limit:(NSUInteger)limit
       connection:(id<ARConnection>)aConnection
{
	NSArray *ids = [self findIds:idOrSpecification
												filter:whereSQL 
													join:joinSQL
												 order:orderSQL
												 limit:limit
										connection:[self defaultConnection]];
  
  NSMutableArray *models = [NSMutableArray array];
  for(NSDictionary *match in ids)
  {
    NSUInteger id = [[match objectForKey:@"id"] unsignedIntValue];
    [models addObject:[[[self alloc] initWithConnection:aConnection id:id] autorelease]];
  }
  return models;
}

+ (NSArray *)findIds:(ARFindSpecification)idOrSpecification
							filter:(NSString *)whereSQL 
								join:(NSString *)joinSQL
							 order:(NSString *)orderSQL 
							 limit:(NSUInteger)limit
					connection:(id<ARConnection>)aConnection
{
  NSMutableString *query = [NSMutableString stringWithFormat:@"SELECT id FROM %@", [self tableName]];
	if(joinSQL)
		[query appendFormat:@" %@", joinSQL];
	
  switch(idOrSpecification)
  {
    case ARFindFirst:
			if(limit == 0)
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
  }
  else if(whereSQL != nil)
      [query appendFormat:@" AND %@", whereSQL];
  
  if(orderSQL != nil)
    [query appendFormat:@" ORDER %@", orderSQL];
  
  if(limit > 0)
    [query appendFormat:@" LIMIT %d", limit];
  
  NSArray *matches = [aConnection executeSQL:query
                               substitutions:[NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInteger:idOrSpecification], @"id", nil]];
  return matches;
}


#pragma mark -
#pragma mark convenience accessors
+ (NSArray *)findAll
{
  return [self find:ARFindAll];
}

+ (id)first
{
	return [self find:ARFindFirst];
}
+ (id)last
{
	NSArray *ret = [self find:ARFindFirst filter:nil join:nil order:@"id DESC" limit:1];
	if(ret && [ret count] > 0)
		return [ret objectAtIndex:0];
	return nil;
}
@end
