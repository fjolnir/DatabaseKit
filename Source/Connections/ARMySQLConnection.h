////////////////////////////////////////////////////////////////////////////////////////////
//
//  ARMySQLConnection.h
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
// NOTE: Assumes UTF-8 encoding on text.
// NOTE: MySQL support is still largely untested, proceed with caution

#import <Foundation/Foundation.h>
#import <ActiveRecord/mysql.h>
#import <ActiveRecord/ARConnection.h>

typedef enum {
  ARMySQLConnectionError = 0
} ARMySQLConnectionErrorCode;

@interface ARMySQLConnection : NSObject <ARConnection> {
  MYSQL *mySQLConnection;
	NSUInteger lastInsertId; // We need to store the insert id ourselves because mysql forgets it as soon as another query is made
}
/*!
 * Returns a ready to use mysql connection\n
 * \n
 * Expects a dictionary with the following keys: host, user, password, database, port
 */
+ (id)openConnectionWithInfo:(NSDictionary *)info error:(NSError **)err;
/*! @copydoc openConnectionWithInfo:error: */
- (id)initWithConnectionInfo:(NSDictionary *)info error:(NSError **)err;

/*! @copydoc ARSQLiteConnection::executeSQL:substitutions: */
- (NSArray *)executeSQL:(NSString *)sql substitutions:(NSDictionary *)substitutions;

/*! @copydoc ARSQLiteConnection::lastInsertId */
- (NSUInteger)lastInsertId;

/*! @copydoc ARSQLiteConnection::closeConnection */
- (BOOL)closeConnection;
/*! @copydoc ARSQLiteConnection::columnsForTable: */
- (NSArray *)columnsForTable:(NSString *)tableName;

/*! @copydoc ARSQLiteConnection::beginTransaction */
- (BOOL)beginTransaction;
/*! @copydoc ARSQLiteConnection::endTransaction */
- (BOOL)endTransaction;

/*!
 * Processes an object into a string valid for use in a query\n
 * \n
 * <b>Note:</b> Will most likely be replaced with mysql's own
 * value binding functionality in the future, so don't count on this
 */
- (NSString *)processArgument:(id)argument;

/*! Returns the libmysqlclient connection itself */
- (MYSQL *)mySQLConnection;
@end
