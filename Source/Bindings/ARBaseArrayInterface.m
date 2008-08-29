//
//  ARBaseArrayInterface.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 23.8.2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ARBaseArrayInterface.h"


@implementation ARBaseArrayInterface
@synthesize queryInfo;
#pragma mark -
#pragma mark Creation
+ (id)find:(ARFindSpecification)idOrSpecification 
{
  return [self find:idOrSpecification
         connection:[ARBase defaultConnection]];
}
+ (id)find:(ARFindSpecification)idOrSpecification connection:(id<ARConnection>)connection
{
  return [self find:idOrSpecification
             filter:nil 
							 join:nil
              order:nil
              limit:0
         connection:connection];
}
+ (id)find:(ARFindSpecification)idOrSpecification 
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
				 connection:[ARBase defaultConnection]];
}

+ (id)find:(ARFindSpecification)idOrSpecification
           filter:(NSString *)whereSQL
						 join:(NSString *)joinSQL
            order:(NSString *)orderSQL
            limit:(NSUInteger)limit
       connection:(id<ARConnection>)aConnection
{
	ARBaseArrayInterface *ret = [[self alloc] init];
	[ret.queryInfo setObject:[NSNumber numberWithInt:idOrSpecification] forKey:@"findSpecification"];
	if(whereSQL)
		[ret.queryInfo setObject:whereSQL forKey:@"whereSQL"];
	if(joinSQL)
		[ret.queryInfo setObject:joinSQL  forKey:@"joinSQL"];
	if(orderSQL)
		[ret.queryInfo setObject:orderSQL forKey:@"orderSQL"];
	[ret.queryInfo setObject:[NSNumber numberWithInt:limit] forKey:@"limit"];
	if(aConnection)
		[ret.queryInfo setObject:aConnection forKey:@"connection"];

	return [ret autorelease];
}
- (id)init
{
	if(![super init])
		return nil;
	self.queryInfo = [NSMutableDictionary dictionary];

	return self;
}

#pragma mark -
+ (NSString *)modelName
{
  NSMutableString *ret = [[[self className] mutableCopy] autorelease];
	[ret replaceOccurrencesOfString:@"ArrayInterface"
											 withString:@""
													options:0
														range:NSMakeRange(0, [ret length])];
	return ret;
}
+ (Class)modelClass
{
	return NSClassFromString([self modelName]);
}

#pragma mark -
#pragma mark Database access
- (NSArray *)matchingIds
{
	Class modelClass = [[self class] modelClass];
	return [modelClass findIds:[[queryInfo objectForKey:@"findSpecification"] intValue]
											filter:[queryInfo objectForKey:@"whereSQL"]
												join:[queryInfo objectForKey:@"joinSQL"]
											 order:[queryInfo objectForKey:@"orderSQL"]
											 limit:[queryInfo objectForKey:@"limit"]
									connection:[queryInfo objectForKey:@"connection"]];
}
- (NSArray *)allObjects
{
	Class modelClass = [[self class] modelClass];
	return (NSArray *)[modelClass find:[[queryInfo objectForKey:@"findSpecification"] intValue]
															filter:[queryInfo objectForKey:@"whereSQL"]
																join:[queryInfo objectForKey:@"joinSQL"]
															 order:[queryInfo objectForKey:@"orderSQL"]
															 limit:[[queryInfo objectForKey:@"limit"] intValue]
													connection:[queryInfo objectForKey:@"connection"]];
}
- (id)objectAtIndex:(NSUInteger)index
{
	// Fetch the id
	Class modelClass = [[self class] modelClass];
	NSArray *ids = [self matchingIds];
	if([ids count] > index)
		return [[[modelClass alloc] initWithId:[[[ids objectAtIndex:index] objectForKey:@"id"] unsignedIntValue]] autorelease];
	return nil;
}
- (id)lastObject
{
	NSUInteger count = [self count];
	if(count > 0)
		return [self objectAtIndex:count - 1];
	return nil;
}
- (void)addObject:(NSDictionary *)attributes
{
	[[[self class] modelClass] createWithAttributes:attributes connection:[queryInfo objectForKey:@"connection"]];
}

- (BOOL)removeObjectAtIndex:(NSUInteger)index
{
	return [[self objectAtIndex:index] destroy];
}

- (NSUInteger)count
{
	return [[self matchingIds] count];
}

#pragma mark -
#pragma mark KVC
- (NSArray *)valueForKey:(NSString *)key
{
	NSMutableArray *ret = [NSMutableArray array];
	for(ARBase *record in [self allObjects])
	{
		[ret addObject:[record valueForKey:key]];
	}
	return ret;
}
- (void)setValue:(id)value forKey:(NSString *)key
{
	for(ARBase *record in [self allObjects])
	{
		[record setValue:value forKey:key];
	}
}
@end
