////////////////////////////////////////////////////////////////////////////////////////////
//
//  DBBase.h
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

#ifndef _DBBASE_H_
#define _DBBASE_H_

#import <Foundation/Foundation.h>
#import <DatabaseKit/DB.h>
#import <DatabaseKit/DBConnection.h>

static NSString * const kDBIdentifierColumn = @"identifier";

@class DBTable;

/*!
 * The abstract base class for the DatabaseKit implementation\n
 * All models are subclasses of DBModel\n
 * \n
 * To use DBModel, subclass it with a class named <prefix>ModelName
 * set the prefix you'll use in +load (along with the default connection if you want one)\n
 * DBModel will then determine the table name (<prefix>ModelName -> modelname)\n
 */
@interface DBModel : NSObject <NSCopying>
@property(readonly, strong) DBTable *table;
@property(readwrite, copy) NSString *identifier;
@property(readonly, getter=isInserted) BOOL inserted;
@property(readonly, retain) NSSet *dirtyKeys;


/*! Returns a model object in the given database
 *  You must set an identifier before saving
 */
- (id)initWithDatabase:(DB *)aDB;

/*! Sets the class prefix for models\n
 * Example: You have a project called TestApp, and therefore all your classes have a TA prefix.\n
 * Suddenly calling your models simply MyModel, would be inconsistent so you set the prefix to "TA" and now calling the model TAMyModel will work
 */
+ (void)setClassPrefix:(NSString *)aPrefix;
/*! Returns the class prefix for models */
+ (NSString *)classPrefix;

/*!
 * Returns the type of a key (along with the class if it is '@')
 */
+ (char)typeForKey:(NSString *)key class:(Class *)outClass;

/*! Saves changes to the database
 */
- (BOOL)save:(NSError **)outErr;
- (BOOL)save;

/*! Deletes a record from the database
 */
- (BOOL)destroy;

/*! Returns the table name of the record based on the class name by converting it to lowercase, pluralizing it and removing the class prefix if one is set. */
+ (NSString *)tableName;

/*! Creates a query with a WHERE clause specifying the record */
- (DBQuery *)query;

@end

#endif /* _DBBASE_H_ */
