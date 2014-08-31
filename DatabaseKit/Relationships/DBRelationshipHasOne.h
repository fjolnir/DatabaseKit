////////////////////////////////////////////////////////////////////////////////////////////
//
//  DBRelationshipHasOne.h
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
#ifndef _DBRELATIONSHIPHASONE_H_
#define _DBRELATIONSHIPHASONE_H_

#import <Foundation/Foundation.h>
#import <DatabaseKit/Relationships/DBRelationship.h>
#import <DatabaseKit/Relationships/DBRelationshipHasMany.h>

/*!
 * A one to one relationship
 * The class that defines this relationship needs an id column for the owner model 
 * (owner = Person => id column = personId)
 * It looks up the owner with the id defined in the record.
 * @code
 * belgian belongs to person
 * =>
 * belgian defines personId as 15
 * Let's say a person has the id 15
 * Then that person owns our belgian 
 * @endcode
 */
@interface DBRelationshipHasOne : DBRelationshipHasMany
@end

@interface DBModel (HasOne)
+ (void)hasOne:(NSString *)parent;
- (NSArray *)hasOne;
@end
#endif /* _DBRELATIONSHIPHASONE_H_ */
