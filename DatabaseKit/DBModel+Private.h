/*! @cond IGNORE */
////////////////////////////////////////////////////////////////////////////////////////////
//
//  DBBasePrivate.h
// 
////////////////////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2007, Fjölnir Ásgeirsson
// 
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
// 
// Redistributions of source code must retain the above copyright notice, this list of conditions
// and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice, this list of
// conditions and the following disclaimer in the documentation and/or other materials provided with 
// the distribution.
// Neither the name of Fjölnir Ásgeirsson nor the names of its contributors may be 
// used to endorse or promote products derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#ifndef _DBBASEPRIVATE_H_
#define _DBBASEPRIVATE_H_

#import "DBModel.h"

@class DBRelationship;

#pragma mark -
#pragma mark Private types
typedef enum { 
  DBAttributeSelectorReader  = 1,
  DBAttributeSelectorWriter,
} DBAttributeSelectorType;

#pragma mark -
#pragma mark Private method definitions
@interface DBModel () // Implemented in DBModel.m
@property(readwrite, retain) NSMutableDictionary *readCache;
@property(readwrite, retain) NSMutableDictionary *writeCache;
@property(readwrite, retain) NSArray *columnCache;

// Returns the column names of the table associated with the model
- (NSArray *)columns;
// Returns the name of the id column (foreign) for a model DBModel would mean modelId
+ (NSString *)idColumnForModel:(Class)modelClass;
+ (NSString *)idColumn;
@end

@interface DBModel (KeyAndSelectorParsers) // Implemented in DBModel-KeyAndSelectorParsers.m
- (DBRelationship *)relationshipForKey:(NSString *)key;
+ (DBAttributeSelectorType)typeOfSelector:(SEL)aSelector
                            attributeName:(NSString **)outAttribute;
@end

/*! @endcond */

#endif /* _DBBASEPRIVATE_H_ */
