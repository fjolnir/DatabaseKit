////////////////////////////////////////////////////////////////////////////////////////////
//
//  ARConnection.h
//   ARConnection is a protocol defining the methods required
//   by active record connection interfaces to implement.
//   It expects a SQL compliant backend (the rest of the framework
//   is built around MySQL&SQLite)
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

@class DBQuery;

#define DBConnectionErrorDomain @"com.activerecord.connection"

@protocol DBConnection <NSObject>
/*!
 * Expects a dictionary with connection info, the required keys differ between connections
 */
+ (id)openConnectionWithInfo:(NSDictionary *)info error:(NSError **)err;
/*! @copydoc openConnectionWithInfo:error: */
- (id)initWithConnectionInfo:(NSDictionary *)info error:(NSError **)err;

/*! @copydoc DBSQLiteConnection::executeSQL:substitutions: */
- (NSArray *)executeSQL:(NSString *)sql substitutions:(id)substitutions error:(NSError **)outErr;
/*! @copydoc DBSQLiteConnection::closeConnection */
- (BOOL)closeConnection;
/*! @copydoc DBSQLiteConnection::columnsForTable: */
- (NSArray *)columnsForTable:(NSString *)tableName;
/*! @copydoc DBSQLiteConnection::beginTransaction */
- (BOOL)beginTransaction;
/*! @copydoc DBSQLiteConnection::endTransaction */
- (BOOL)endTransaction;
/*! @copydoc DBSQLiteConnection::lastInsertId */
- (NSUInteger)lastInsertId;
@end
