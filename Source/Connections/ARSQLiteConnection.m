//
//  ARSQLiteConnection.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#define LOG_QUERIES NO

#import "ARSQLiteConnection.h"
#import <unistd.h>

/*! @cond IGNORE */
@interface ARSQLiteConnection ()
- (sqlite3_stmt *)prepareQuerySQL:(NSString *)query;
- (void)finalizeQuery:(sqlite3_stmt *)query;
- (NSArray *)columnsForQuery:(sqlite3_stmt *)query;
- (id)valueForColumn:(unsigned int)colIndex query:(sqlite3_stmt *)query;
@end
/*! @endcond */

#pragma mark -

@implementation ARSQLiteConnection
#pragma mark -
#pragma mark Initialization
+ (id)openConnectionWithInfo:(NSDictionary *)info error:(NSError **)err
{
  return [[[self alloc] initWithConnectionInfo:info error:err] autorelease];
}
- (id)initWithConnectionInfo:(NSDictionary *)info error:(NSError **)err
{
  NSString *path = [info objectForKey:@"path"] ? [info objectForKey:@"path"] : @"";
  if(![path isEqualToString:@":memory:"] && ![[NSFileManager defaultManager] fileExistsAtPath:path])
  {
    if(err != NULL) {
      *err = [NSError errorWithDomain:@"database.sqlite.filenotfound" 
                                 code:ARSQLiteDatabaseNotFoundErrorCode 
                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                       NSLocalizedString(@"SQLite database not found", @""), NSLocalizedDescriptionKey,
                                       path, NSFilePathErrorKey, nil]];
    }
    return nil;
  }
  // Else
  int sqliteError = 0;
  sqliteError = sqlite3_open([path UTF8String], &database);
  if(sqliteError != SQLITE_OK)
  {
    const char *errStr = sqlite3_errmsg(database);
    if(err != NULL) {
      *err = [NSError errorWithDomain:@"database.sqlite.openerror" 
                                 code:ARSQLiteDatabaseNotFoundErrorCode 
                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSString stringWithUTF8String:errStr], NSLocalizedDescriptionKey,
                                     path, NSFilePathErrorKey, nil]];
    }
    return nil;
  }
  
  
  return self;
}

+ (ARSQLiteConnection *)openConnectionToInMemoryDatabase:(NSError **)err {
  return [self openConnectionWithInfo:[NSDictionary dictionaryWithObject:@":memory:" forKey:@"path"] error:err];
}


#pragma mark -
#pragma mark SQL Eecuting
- (NSArray *)executeSQL:(NSString *)sql substitutions:(NSDictionary *)substitutions
{
	//ARDebugLog(@"Executing SQL: %@ subs: %@", sql, substitutions);
  // Prepare the query
  sqlite3_stmt *queryByteCode;
  queryByteCode = [self prepareQuerySQL:sql];
	NSArray *columnNames = [self columnsForQuery:queryByteCode];

	for(int i = 1; i <= sqlite3_bind_parameter_count(queryByteCode); ++i)
	{
		const char *keyCstring = sqlite3_bind_parameter_name(queryByteCode, i);
		if(!keyCstring)
			continue;
		
	  NSString *key = [[NSString stringWithUTF8String:keyCstring] stringByReplacingOccurrencesOfString:@":" withString:@""];
		id sub = [substitutions objectForKey:key];
		if(!sub)
			continue;
		if([sub isKindOfClass:[NSString class]] || [[sub className] isEqualToString:@"NSCFString"])
			sqlite3_bind_text(queryByteCode, i, [sub UTF8String], -1, SQLITE_TRANSIENT);
		else if([sub isMemberOfClass:[NSData class]])
			sqlite3_bind_blob(queryByteCode, i, [sub bytes], [sub length], SQLITE_STATIC); // Not sure if we should make this transient
		else if([sub isKindOfClass:[NSNumber class]])
			sqlite3_bind_double(queryByteCode, i, [sub doubleValue]);
		else if([sub isMemberOfClass:[NSNull class]])
			sqlite3_bind_null(queryByteCode, i);
		else
			[NSException raise:@"Unrecognized object type" format:@"Active record doesn't know how to handle this type of object: %@ class: %@", sub, [sub className]];
	}
  
  NSMutableArray *rowArray = [NSMutableArray array];
  NSMutableDictionary *columns;
  int err = 0;
  while((err = sqlite3_step(queryByteCode)) != SQLITE_DONE)
  {
    if(err == SQLITE_BUSY)
    {
      ARDebugLog(@"busy!");
      usleep(100); // TODO: maybe *not* halt app execution if the database is busy?
    }
    else if(err == SQLITE_ERROR || err == SQLITE_MISUSE)
    {
      [NSException raise:@"SQLite error"
                  format:@"Query: %@ Details: %@", sql, [NSString stringWithUTF8String:sqlite3_errmsg(database)]];
      break;
    }
    else if(err == SQLITE_ROW)
    {
      // construct the dictionary for the row
      columns = [NSMutableDictionary dictionary];
      int i = 0;
      for (NSString *columnName in columnNames)
      {
        [columns setObject:[self valueForColumn:i query:queryByteCode]
                    forKey:columnName];
        ++i;
      }
      [rowArray addObject:columns];
    }
  }
  
  [self finalizeQuery:queryByteCode];
  return rowArray;
}

- (NSUInteger)lastInsertId
{
  return (NSUInteger)sqlite3_last_insert_rowid(database);
}

- (NSArray *)columnsForTable:(NSString *)tableName
{
  sqlite3_stmt *queryByteCode = [self prepareQuerySQL:[NSString stringWithFormat:@"SELECT * FROM %@", tableName]];
  NSArray *columns = [self columnsForQuery:queryByteCode];
  [self finalizeQuery:queryByteCode];
  return columns;
}

- (BOOL)closeConnection
{
  return sqlite3_close(database) == SQLITE_OK;
}

#pragma mark Private
- (NSArray *)columnsForQuery:(sqlite3_stmt *)query
{
  int columnCount = sqlite3_column_count(query);
  if(columnCount <= 0)
    return nil;
  
  NSMutableArray *columnNames = [NSMutableArray array];
  for(int i = 0; i < columnCount; ++i)
  {
    const char *name;
    name = sqlite3_column_name(query, i);
    [columnNames addObject:[NSString stringWithUTF8String:name]];
  }
  return columnNames;
}
- (sqlite3_stmt *)prepareQuerySQL:(NSString *)query
{
  if(LOG_QUERIES)
    ARDebugLog(@"Preparing query: %@", query);
  // Prepare the query
  sqlite3_stmt *queryByteCode;
  const char *tail;
  int err = sqlite3_prepare_v2(database, 
                            [query UTF8String], 
                            [query lengthOfBytesUsingEncoding:NSUTF8StringEncoding], 
                            &queryByteCode, 
                            &tail);
  if(err != SQLITE_OK || queryByteCode == NULL)
  {
    [NSException raise:@"SQLite error" 
                format:@"Couldn't compile the query(%@), Details: %@", query, [NSString stringWithUTF8String:sqlite3_errmsg(database)]];
    
    return nil;
  }
  
  return queryByteCode;
}
- (void)finalizeQuery:(sqlite3_stmt *)query
{
  sqlite3_finalize(query);
}

// You have to step through the *query yourself,
- (id)valueForColumn:(unsigned int)colIndex query:(sqlite3_stmt *)query
{
  int columnType = sqlite3_column_type(query, colIndex);
  switch(columnType)
  {
    case SQLITE_INTEGER:
      return [NSNumber numberWithInt:sqlite3_column_int(query, colIndex)];
      break;
    case SQLITE_FLOAT:
      return [NSNumber numberWithDouble:sqlite3_column_double(query, colIndex)];
      break;
    case SQLITE_BLOB:
      return [NSData dataWithBytes:sqlite3_column_blob(query, colIndex)
                            length:sqlite3_column_bytes(query, colIndex)];
      break;
    case SQLITE_NULL:
      return [NSNull null];
      break;
    case SQLITE_TEXT:
      return [NSString stringWithUTF8String:(const char *)sqlite3_column_text(query, colIndex)];
      break;
    default:
      // It really shouldn't ever come to this.
      break;
  }
  return nil;
}

#pragma mark -
#pragma mark Transactions
- (BOOL)beginTransaction
{
  char *errorMessage;
  int err = sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
  if(err != SQLITE_OK)
  {
    [NSException raise:@"SQLite error" 
                format:@"Couldn't start transaction, Details: %@", [NSString stringWithUTF8String:errorMessage]];
    return NO;
  }
  return YES;
}
- (BOOL)endTransaction
{
  char *errorMessage;
  int err = sqlite3_exec(database, "END TRANSACTION", NULL, NULL, &errorMessage);
  if(err != SQLITE_OK)
  {
    [NSException raise:@"SQLite error" 
                format:@"Couldn't end transaction, Details: %@", [NSString stringWithUTF8String:errorMessage]];
    return NO;
  }
  return YES;
}

#pragma mark -
#pragma mark Cleanup
- (void)finalize
{
  [super finalize];
  [self closeConnection];
}
- (void)dealloc
{
  [self closeConnection];
  [super dealloc];
}
@end

/* old stuff (might be useful for other databases): 
 // Apply substitutions (if any)
 // Because we supported ":key" as opposed to only "?" like sqlite does
 // We need to convert the dictionary to an array of arguments, and convert the keys to ?'s
 // in order to be able to use sqlite's built in value binding
 NSMutableString *mutableSQL = [sql mutableCopy];
 	NSArray *orderedSubstitutions = nil;
 if(substitutions != nil)
 {
 NSLog(@"..");
 NSMutableDictionary *subsByLocation = [NSMutableDictionary dictionary];
 for(NSString *key in substitutions)
 {
 NSRange range = [sql rangeOfString:[NSString stringWithFormat:@":%@", key]];
 NSLog(@"looking for :%@ in %@ - loc: %d", key, sql, range.location);
 
 if(range.location == NSNotFound)
 continue;
 [subsByLocation setObject:[NSNumber numberWithInt:range.location] forKey:[substitutions objectForKey:key]];
 [mutableSQL replaceCharactersInRange:range withString:@"?"];
 }
 orderedSubstitutions = [subsByLocation keysSortedByValueUsingSelector:@selector(compare:)];
 }
 NSLog(@"orderedSubstitutions=%@", orderedSubstitutions);

*/
