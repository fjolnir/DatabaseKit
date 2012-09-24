////////////////////////////////////////////////////////////////////////////////////////////
//
//  ARSTable.h
//  Database table abstraction
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

#import <Foundation/Foundation.h>
#import <ActiveRecord/ARConnection.h>

@interface ARTable : NSObject
@property(readonly, strong) NSString *name;
@property(readonly, strong) id<ARConnection> connection;

+ (ARTable *)withName:(NSString *)name;
+ (ARTable *)withConnection:(id<ARConnection>)connection name:(NSString *)name;

- (NSString *)toString;

- (Class)modelClass;

- (ARQuery *)select:(id)fields;
- (ARQuery *)select;
- (ARQuery *)insert:(id)fields;
- (ARQuery *)update:(id)fields;
- (ARQuery *)delete;
- (ARQuery *)where:(id)conds;
- (ARQuery *)order:(NSString *)order by:(id)fields;
- (ARQuery *)orderBy:(id)fields;
- (ARQuery *)limit:(NSNumber *)limit;
@end
