//
//  NSArray+ARAdditions.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 11/23/07.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import "NSArray+ARAdditions.h"

/* @cond IGNORE */
@implementation NSArray (ARAdditions)
- (NSMutableArray *)arrayByRemovingDuplicates // This seems ugly, todo: beutify
{
  NSMutableArray *ret = [NSMutableArray arrayWithArray:self];
  for(id item in ret)
  {
		[item retain];
    [ret removeObjectIdenticalTo:item];
		[ret addObject:item];
		[item release];
  }
  return ret;
}
@end
/* @endcond */