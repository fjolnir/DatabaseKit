//
//  NSArray+DBAdditions.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 11/23/07.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import "NSArray+DBAdditions.h"

/* @cond IGNORE */
@implementation NSArray (DBAdditions)
- (NSMutableArray *)arrayByRemovingDuplicates // This seems ugly, todo: beutify
{
  NSMutableArray *ret = [NSMutableArray arrayWithArray:self];
  for(id item in ret)
  {
    [ret removeObjectIdenticalTo:item];
		[ret addObject:item];
  }
  return ret;
}
@end
/* @endcond */