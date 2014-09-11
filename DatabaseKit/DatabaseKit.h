////////////////////////////////////////////////////////////////////////////////////////////
//
// DatabaseKit.h
// A simple to use database framework.
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
#ifndef _ACTIVERECORD_H_ 
#define _ACTIVERECORD_H_ 
#import <DatabaseKit/DB.h>
#import <DatabaseKit/DBTable.h>
#import <DatabaseKit/Queries/DBQuery.h>
#import <DatabaseKit/DBModel.h>

#import <DatabaseKit/Connections/DBConnection.h>
#import <DatabaseKit/Connections/DBConnectionPool.h>
#import <DatabaseKit/Connections/DBSQLiteConnection.h>
#import <DatabaseKit/Connections/DBPostgresConnection.h>

#import <DatabaseKit/Relationships/DBRelationship.h>
#import <DatabaseKit/Relationships/DBRelationshipHasMany.h>
#import <DatabaseKit/Relationships/DBRelationshipHasManyThrough.h>
#import <DatabaseKit/Relationships/DBRelationshipHasOne.h>
#import <DatabaseKit/Relationships/DBRelationshipBelongsTo.h>
#import <DatabaseKit/Relationships/DBRelationshipHABTM.h>
#import <DatabaseKit/Relationships/DBRelationshipColumn.h>

#endif /* _ACTIVERECORD_H_ */
