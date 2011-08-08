//
//  NSArray+ARAdditions.h
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 11/23/07.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//
#ifndef _NSARRAY_ARADDITIONS_H_
#define _NSARRAY_ARADDITIONS_H_

#import <Foundation/Foundation.h>

@interface NSArray (ARAdditions)
/*!
 * Returns an array with all duplicates reduced to one copy of the object\n
 * [a a b c] -> [a b c]
 */
- (NSMutableArray *)arrayByRemovingDuplicates;
@end
#endif /* _NSARRAY+ARADDITIONS_H_ */
