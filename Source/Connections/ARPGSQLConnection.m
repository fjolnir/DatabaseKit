//
//  ARPGSQLConnection.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#define LOG_QUERIES NO

#import "ARPGSQLConnection.h"
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
	if(![super init])
		return nil;
	BOOL connected = [self connectWithArguments:info error:err];
	if(!connected)
		return nil;
	
  return self;
}

- (BOOL)connectWithHost:(NSString *)host 
                   user:(NSString *)username
               password:(NSString *)password
               database:(NSString *)databaseName
                   port:(NSUInteger)port
                  error:(NSError **)err
{
	return [self connectWithArguments:[NSDictionary dictionaryWithObjectsAndKeys:
																			host, @"host", 
																			username, @"username",
																			password, @"password",
																			databaseName, @"dbname",
																			[NSString stringWithFormat:@"%d", port], @"port"]
															error:err]; 

}
- (BOOL)connectWithArguments:(NSDictionary *)arguments error:(NSError **)err
{
	NSMutableString *connStr = [NSMutableString string];
	for(NSString *key in [arguments allKeys])
	{
			[connStr appendFormat:@"%@=%@", key, [arguments objectForKey:key]];
	}
	database = PQconnectdb([connStr UTF8String]);
	ConnStatusType status = PQstatus(database);
	if(status == CONNECTION_BAD)
	{
		*err = [NSError errorWithDomain:@"database.pgsql.connection"
															 code:ARPGSQDatabaseConnectionFailed 
													 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [self lastErrorMessage], NSLocalizedDescriptionKey, nil]];
		return NO;
	}
	return YES;
}

#pragma mark -
#pragma mark SQL Eecuting
- (NSArray *)executeSQL:(NSString *)sql substitutions:(NSDictionary *)substitutions
{
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
		if([sub isMemberOfClass:[NSString class]] || [[sub className] isEqualToString:@"NSCFString"])
			sqlite3_bind_text(queryByteCode, i, [sub UTF8String], [sub length], SQLITE_TRANSIENT);
		else if([sub isMemberOfClass:[NSData class]])
			sqlite3_bind_blob(queryByteCode, i, [sub bytes], [sub length], SQLITE_STATIC); // Not sure if we should make this transient
		else if([[sub className] isEqualToString:@"NSCFNumber"])
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

- (NSString *)lastErrorMessage
{
	return [NSString stringWithFormat:@"%s", PQerrorMessage(database)];
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
  PQfinish(database);
	if(PQstatus(database) == CONNECTION_BAD)
		return YES;
	return NO;
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
- (PGresult *)prepareQuerySQL:(NSString *)query
{
  if(LOG_QUERIES)
    ARDebugLog(@"Preparing query: %@", query);
  // Prepare the query
  PGresult *query;
	query = PQPrepare(database, "", [query UTF8String], 0, NULL);
	ConnStatusType status = PQstatus(database);
	if(status == CONNECTION_BAD)
	{
		[NSException raise:@"PGSQL error" 
                format:@"Couldn't compile the query(%@), Details: %@", query, [self lastErrorMessage];
		return NULL;
	}
	return query;
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
