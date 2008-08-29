////////////////////////////////////////////////////////////////////////////////////////////
//
// ARBaseArrayInterface.h
// An NSArray style interface to ARBase records
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
// Neither the name of Fjölnir Ásgeirsson, ninja kitten nor the names of its contributors may be 
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
#ifndef _ARBASE_ARRAYINTERFACE_H_
#define _ARBASE_ARRAYINTERFACE_H_
#import <Cocoa/Cocoa.h>
#import <ActiveRecord/ARBase.h>

/*!
 * An NSArray style interface to ARBase records\n
 * \n
 * The interface is by no means compatible with NSMutableArray. It implements only what's required to
 * implement binding support for ActiveRecord\n
 * \n
 * To use ARBaseArrayInterface, subclass it with a class named <prefix>ModelNameArrayInterface
 * ARBaseArrayInterface will then determine the name of the model to use  (<prefix>ModelNameArrayInterface -> modelname)\n
 * \n
 * <b>Do not</b> use ARBaseArrayInterface directly. Hic sunt dracones
 */
@interface ARBaseArrayInterface : NSObject {
	NSMutableDictionary *queryInfo;
}
@property(readwrite, retain) NSMutableDictionary *queryInfo;

/*! Finds records based on the find specification. 
 * @param idOrSpecification The find specification
 */
+ (id)find:(ARFindSpecification)idOrSpecification;
/*! Finds records based on the find specification, filter and limit using the specified connection. 
 * @param idOrSpecification The find specification
 * @param limit The maximum number of records to retrieve
 */
+ (id)find:(ARFindSpecification)idOrSpecification connection:(id<ARConnection>)connection;
/*! Finds records based on the find specification, filter and limit. 
 * @param idOrSpecification The find specification
 * @param whereSQL A valid SQL WHERE statement (omitting the actual "WHERE")
 * @param orderSQL A valud SQL ORDER statement (omitting the actual "ORDER BY")
 * @param limit The maximum number of records to retrieve
 */
+ (id)find:(ARFindSpecification)idOrSpecification 
           filter:(NSString *)whereSQL
						 join:(NSString *)joinSQL
						order:(NSString *)orderSQL
            limit:(NSUInteger)limit;

/*! Finds records based on the find specification, filter and limit using the specified connection. 
 * @param idOrSpecification The find specification
 * @param whereSQL A valid SQL WHERE statement (omitting the actual "WHERE")
 * @param orderSQL A valud SQL ORDER statement (omitting the actual "ORDER BY")
 * @param limit The maximum number of records to retrieve
 * @param connection The connection to use for the record. (Pass nil to use the default connection)
 */
+ (id)find:(ARFindSpecification)idOrSpecification
												filter:(NSString *)whereSQL
													join:(NSString *)joinSQL
												 order:(NSString *)orderSQL
												 limit:(NSUInteger)limit
										connection:(id<ARConnection>)aConnection;

/*! Returns the class name of the model to use */
+ (NSString *)modelName;
/*! Returns the model class to use */
+ (Class)modelClass;

/*! Returns an array of dictionaries containing the database ids matching records */
- (NSArray *)matchingIds;
/*! Returns an array of records matching the find specification */
- (NSArray *)allObjects;

/*! Returns the nth record matching the find specification\n
 * @param index The index to look up
 */
- (id)objectAtIndex:(NSUInteger)index;
/*! Returns the last record matching the find specification */
- (id)lastObject;

/*! Adds a record to the database
 * @param object A NSDictionary containing attributes for the record.
 */
- (void)addObject:(NSDictionary *)attributes;

/*! Destroys the nth record matching the find specification
 * @param index The index of the record to destroy
 */
- (BOOL)removeObjectAtIndex:(NSUInteger)index;

/*! Returns the number of records matching the find specification */
- (NSUInteger)count;

/*! Returns an array containing the results of invoking valueForKey: using key on each of the receiver's records. */
- (NSArray *)valueForKey:(NSString *)key;
/*! Invokes setValue:forKey: on each of the receiver's records using the specified value and key. */
- (void)setValue:(id)value forKey:(NSString *)key;
@end
#endif _ARBASE_ARRAYINTERFACE_H_