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
#import <DatabaseKit/Connections/DBConnection.h>

@class DBTable;

/*!
 * The abstract base class for the DatabaseKit implementation\n
 * All models are subclasses of DBModel\n
 * \n
 * To use DBModel, subclass it with a class named <prefix>ModelName
 * set the prefix you'll use in +load (along with the default connection if you want one)\n
 * DBModel will then determine the table name (<prefix>ModelName -> modelname)\n
 */
@interface DBModel : NSObject
@property(readonly, strong) DBTable *table;
@property(readwrite, strong) NSMutableArray *relationships;
@property(readwrite) NSUInteger databaseId;

/*! Creates a reference to the record corresponding to id\n
 * Note: Does not check if the record exists
 * @param aConnection the connection to use
 * @param id The id of the record to retrieve
 */
- (id)initWithTable:(DBTable *)aTable databaseId:(NSUInteger)aDatabaseId;

/*! Sets the class prefix for models\n
 * Example: You have a project called TestApp, and therefore all your classes have a TA prefix.\n
 * Suddenly calling your models simply MyModel, would be inconsistent so you set the prefix to "TA" and now calling the model TAMyModel will work
 */
+ (void)setClassPrefix:(NSString *)aPrefix;
/*! Returns the class prefix for models */
+ (NSString *)classPrefix;

/*! Returns wether DatabaseKit will cache records retrieved from the database */
+ (BOOL)enableCache;
/*! Sets wether DatabaseKit will cache records retrieved from the database */
+ (void)setEnableCache:(BOOL)flag;
/*! Refetches all cached values */
- (void)refreshCache;

/*! Returns wether DBModel and it's subclasses will hold off writing changes to the database until told to save */
+ (BOOL)delayWriting;
/*! Sets wether DBModel and it's subclasses will hold off writing changes to the database until told to save */
+ (void)setDelayWriting:(BOOL)flag;
/*! Saves queued changes \n
 * Does nothing if delayWriting is NO
 */
- (void)save;

/*! Deletes a record from the database\n
 * Deletes instantly regardless of wether delayWriting is set to YES\n
 * If the record is successfully deleted the model object is released
 */
- (BOOL)destroy;

/*! Returns the table name of the record based on the class name by converting it to lowercase, pluralizing it and removing the class prefix if one is set. */
+ (NSString *)tableName;

/*! Returns the relationship the record has. */
+ (NSMutableArray *)relationships;

/*! Creates a query with a WHERE clause specifying the record */
- (DBQuery *)query;

// Accessors
/*! Sets a value in the database. If caching is enabled, the cache for key will be updated\n
 * <b>Note: </b> Ignores delayedWriting, if you want to use that use setValue:forKey: instead
 * @param key A valid key, can refer to either a column or a relationship
 * @param value The value to set, can be any object recognized by DBKit
 */
- (void)sendValue:(id)value forKey:(NSString *)key;

/*! Sets a value in the database. If caching is enabled, the cache for key will be updated\n
 * If delayedWriting is YES it will hold off writing changes to the database until told to save
 * @param key A valid key, can refer to either a column or a relationship
 * @param value The value to set, can be any object recognized by DBKit
 */
- (void)setValue:(id)obj forKey:(NSString *)key;
/*!
 * Retrieves a value from the database\n
 * If caching is enabled the method will check if the value for the specified key has been cached,
 * if it has, then the cached value is returned otherwise it will be fetched from the database
 * @param key A valid key, can refer to either a column or a relationship
 */
- (id)valueForKey:(NSString *)key;
/*!
 * Retrieves a value from the database\n
 * Same as retrieveValueForKey:
 * @param key A valid key, can refer to either a column or a relationship
 */
- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key;
@end

#endif /* _DBBASE_H_ */
