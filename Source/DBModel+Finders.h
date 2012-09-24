////////////////////////////////////////////////////////////////////////////////////////////
//
//  ARBase+Finders.h
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
#ifndef _DBBASE_FINDERS_H_
#define _DBBASE_FINDERS_H_

#import <DatabaseKit/DBModel.h>

@interface DBModel (Finders)
// Finders
/*! Finds a record based on the find specification. 
 * @param idOrSpecification The find specification
 */
+ (NSArray *)find:(DBFindSpecification)idOrSpecification;
/*! Finds a record based on the find specification, filter and limit using the specified connection. 
 * @param idOrSpecification The find specification
 * @param limit The maximum number of records to retrieve
 */
+ (NSArray *)find:(DBFindSpecification)idOrSpecification connection:(DBConnection *)connection;
/*! Finds a record based on the find specification, filter and limit. 
 * @param idOrSpecification The find specification
 * @param whereSQL A valid SQL WHERE statement (omitting the actual "WHERE")
 * @param orderSQL A valud SQL ORDER statement (omitting the actual "ORDER BY")
 * @param limit The maximum number of records to retrieve
 */
+ (NSArray *)find:(DBFindSpecification)idOrSpecification 
           filter:(id)filter
             join:(NSString *)joinSQL
            order:(NSString *)order
            limit:(NSUInteger)limit;
/*! Finds a record based on the find specification, filter and limit using the specified connection. 
 * @param idOrSpecification The find specification
 * @param whereSQL A valid SQL WHERE statement (omitting the actual "WHERE")
 * @param orderSQL A valud SQL ORDER statement (omitting the actual "ORDER BY")
 * @param limit The maximum number of records to retrieve
 * @param connection The connection to use for the record. (Pass nil to use the default connection)
 */
+ (NSArray *)find:(DBFindSpecification)idOrSpecification
           filter:(id)filter
             join:(NSString *)joinSQL
            order:(NSString *)order
            limit:(NSUInteger)limit
       connection:(DBConnection *)aConnection;
/*! Finds ids of records matching the find specification, filter and limit using the specified connection.\n
 * You generally won't need to use this method, but it can be useful in cases where you just want to know for example\n
 * The number of records matching.
 * @param idOrSpecification The find specification
 * @param whereSQL A valid SQL WHERE statement (omitting the actual "WHERE")
 * @param orderSQL A valud SQL ORDER statement (omitting the actual "ORDER BY")
 * @param limit The maximum number of records to retrieve
 * @param connection The connection to use for the record. (Pass nil to use the default connection)
 */
+ (NSArray *)findIds:(DBFindSpecification)idOrSpecification
              filter:(id)filter
                join:(NSString *)joinSQL
               order:(NSString *)order
               limit:(NSUInteger)limit
          connection:(DBConnection *)aConnection;

/*! Finds all of the model's records */
+ (NSArray *)findAll;
/*! Finds the first record */
+ (id)first;
/*! Finds the first record matching filter*/
+ (id)first:(NSString *)filter;
/*! Finds the last record */
+ (id)last;
@end
#endif /* _DBBASEFINDERS_H_ */
