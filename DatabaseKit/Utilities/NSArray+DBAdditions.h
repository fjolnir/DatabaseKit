//
//  NSArray+DBAdditions.h
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 11/23/07.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//
#ifndef _NSDBRAY_DBADDITIONS_H_
#define _NSDBRAY_DBADDITIONS_H_

#import <Foundation/Foundation.h>

@interface NSArray (DBAdditions)
/*!
 * Returns an array with all duplicates reduced to one copy of the object\n
 * [a a b c] -> [a b c]
 */
- (NSMutableArray *)arrayByRemovingDuplicates;
@end
#endif /* _NSDBRAY+DBADDITIONS_H_ */
