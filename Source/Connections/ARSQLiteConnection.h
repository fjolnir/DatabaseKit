////////////////////////////////////////////////////////////////////////////////////////////
//
//  ARSQLiteConnection.h
//   SQLite 3 adapter
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
#ifndef _ARSQLITECONNECTION_H_
#define _ARSQLITECONNECTION_H_

#import <Foundation/Foundation.h>
#import <ActiveRecord/ARConnection.h>
#import <sqlite3.h>

@class ARQuery;

typedef enum  {
  ARSQLiteDatabaseNotFoundErrorCode = 0
} ARSQLiteErrorCode;

@interface ARSQLiteConnection : NSObject <ARConnection> {
  sqlite3 *database;
}
/*!
 * Returns a ready to use sqlite "connection"\n
 * \n
 * Expects a dictionary with a single key: "path" which is the path to
 * the SQLite3 database file, sets 'err' and returns nil on error
 *
 * @param info A dictionary containing the path (key: "path")to the database (can be an in memory database)
 * @param err Set to an NSError object on failure.
 */
+ (id)openConnectionWithInfo:(NSDictionary *)info error:(NSError **)err;
/*! @copydoc openConnectionWithInfo:error: */
- (id)initWithConnectionInfo:(NSDictionary *)info error:(NSError **)err;

/*!
 * Returns a ready to use sqlite "connection" to an in memory database
 * \n
 * Creates an empty SQLite database in memory and returns a connection to it
 */
+ (ARSQLiteConnection *)openConnectionToInMemoryDatabase:(NSError **)err;

/*!
 * Executes the given SQL string after making substitutions(optional, pass nil if none should be made).
 * Substitutions should be used for values, not column/table names since
 * they're formatted as values
 *
 * Example usage:
 * @code
 * [myConnection executeSQL:@"INSERT INTO mymodel(id, name) VALUES(:id, :name)"
 *            substitutions:[NSDictionary dictionaryWithObjectsAndKeys:
 *                           myId, @"id",
 *                           name, @"name"]];
 * @endcode
 */
- (NSArray *)executeSQL:(NSString *)sql substitutions:(NSDictionary *)substitutions;

/*!
 * Executes a query object
 */
- (NSArray *)executeQuery:(ARQuery *)query;

/*!
 * Returns the id of the row last inserted into
 */
- (NSUInteger)lastInsertId;

/*!
 * Closes the connection\n
 * does <b>not</b> release the object object itself
 */
- (BOOL)closeConnection;
/*!
 * Returns an array of strings containing the column names for the given table
 * @param tableName Name of the table to retrieve columns for
 */
- (NSArray *)columnsForTable:(NSString *)tableName;

/*! Begins a transaction */
- (BOOL)beginTransaction;
/*! Ends a transaction */
- (BOOL)endTransaction;
@end

#endif /* _ARSQLITECONNECTION_H_ */
