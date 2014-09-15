////////////////////////////////////////////////////////////////////////////////////////////
//
//  DBSTable.h
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
#import <DatabaseKit/DB.h>

@class DBQuery, DBSelectQuery, DBInsertQuery, DBUpdateQuery, DBDeleteQuery, DBRawQuery;

@interface DBTable : NSObject
@property(readonly, strong) NSString *name;
@property(readonly, strong) DB *database;
@property(readonly, strong) NSSet *columns;

+ (DBTable *)withDatabase:(DB *)database name:(NSString *)name;

- (NSString *)toString;
- (Class)modelClass;

- (id)objectForKeyedSubscript:(id)cond;
- (void)setObject:(id)obj forKeyedSubscript:(id)cond;

- (DBSelectQuery *)select:(NSArray *)fields;
- (DBSelectQuery *)select;
- (DBInsertQuery *)insert:(NSDictionary *)fields;
- (DBUpdateQuery *)update:(NSDictionary *)fields;
- (DBDeleteQuery *)delete;
- (DBQuery *)where:(id)conds;
- (DBSelectQuery *)order:(NSString *)order by:(id)fields;
- (DBSelectQuery *)orderBy:(id)fields;
- (DBSelectQuery *)limit:(NSUInteger)limit;
- (DBRawQuery *)rawQuery:(NSString *)SQL;

- (NSUInteger)count;
@end
