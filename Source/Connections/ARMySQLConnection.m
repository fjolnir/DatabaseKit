//
//  ARMySQLConnection.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 15.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import "ARMySQLConnection.h"
#import "ARMySQLField.h"

/*! @cond IGNORE */
@interface ARMySQLConnection ()
- (NSString *)lastErrorMessage;
- (BOOL)ping;
- (BOOL)connectWithHost:(NSString *)host 
                   user:(NSString *)username
               password:(NSString *)password
               database:(NSString *)database
                   port:(NSUInteger)port
                  error:(NSError **)err;
- (NSString *)applySubstitutions:(NSDictionary *)substitutions onQuery:(NSString *)query;
- (NSString *)prepareString:(NSString *)string;
- (NSString *)prepareData:(NSData *)data;
- (NSString *)prepareDate:(NSCalendarDate *)date;
- (NSString *)prepareNumber:(NSNumber *)number;
@end
/*! @endcond */

@implementation ARMySQLConnection
+ (id)openConnectionWithInfo:(NSDictionary *)info error:(NSError **)err
{
  return [[[self alloc] initWithConnectionInfo:info error:err] autorelease];
}
- (id)initWithConnectionInfo:(NSDictionary *)info error:(NSError **)err
{
  if(!(self = [super init]))
    return nil;
  mySQLConnection = mysql_init(mySQLConnection);
  BOOL connected = [self connectWithHost:[info objectForKey:@"host"] 
                                    user:[info objectForKey:@"user"]
                                password:[info objectForKey:@"password"]
                                database:[info objectForKey:@"database"]
                                    port:[[info objectForKey:@"port"] unsignedIntValue]
                                   error:err];
  if(!connected)
    return nil;  
  
  return self;
}

#pragma mark -
#pragma mark Connecting code
- (BOOL)connectWithHost:(NSString *)host 
                   user:(NSString *)username
               password:(NSString *)password
               database:(NSString *)database
                   port:(NSUInteger)port
                  error:(NSError **)err
{
  MYSQL *res;
  mySQLConnection = mysql_init(mySQLConnection);
  res = mysql_real_connect(mySQLConnection,
                           [host UTF8String],
                           [username UTF8String],
                           [password UTF8String],
                           [database UTF8String],
                           port, NULL, 0);
  if(res == NULL)
  {
	  NSLog(@"error!");
    if(err != NULL) {
      *err = [NSError errorWithDomain:@"database.mysql.connection" 
                                 code:ARMySQLConnectionError 
                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                       [self lastErrorMessage], NSLocalizedDescriptionKey, nil]];
    }
    return NO;
  }
  return YES;
}

- (BOOL)ping
{
  return (BOOL)!mysql_ping(mySQLConnection);
}
#pragma mark -
#pragma mark Database access
- (NSArray *)executeSQL:(NSString *)sql substitutions:(NSDictionary *)substitutions
{
	ARDebugLog(@"Executing SQL: %@ subs: %@", sql, substitutions);
  sql = [self applySubstitutions:substitutions onQuery:sql];
  int status = mysql_query(mySQLConnection, [sql UTF8String]);
  if(status == 0)
  {
    MYSQL_RES *result = mysql_store_result(mySQLConnection);
    if(result)
    {
      unsigned int numFields = mysql_num_fields(result);
      unsigned int numRows = mysql_num_rows(result);
      
      NSArray *fields = [ARMySQLField fieldsForResult:result];
      NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:numRows];
      MYSQL_ROW row;
      while((row = mysql_fetch_row(result)))
      {
        unsigned long *lengths = mysql_fetch_lengths(result);
        NSMutableDictionary *rowDict = [NSMutableDictionary dictionaryWithCapacity:numFields];
        for(int columnIndex = 0; columnIndex < numFields; ++columnIndex)
        {
          ARMySQLField *field = [fields objectAtIndex:columnIndex];
          id value = [field objectForData:row[columnIndex] length:lengths[columnIndex]];
          [rowDict setObject:value 
                      forKey:field.name];
        }
        [resultArray addObject:rowDict];
      }
      mysql_free_result(result);
      return resultArray;
    }
    else
    {
			// Check if the query should have returned data.
			if(mysql_field_count(mySQLConnection) != 0)
        [NSException raise:@"MySQL error" format:@"Data should have been returned but wasn't!"];
			else
				lastInsertId = mysql_insert_id(mySQLConnection);
			// If not, it was an INSERT query and no info should be returned
      return nil;
    }
  }
	else
		
	NSLog(@"err: %@", [self lastErrorMessage]);
  return nil;
}
- (BOOL)closeConnection
{
  mysql_close(mySQLConnection);
  return YES;
}
- (MYSQL *)mySQLConnection
{
	return mySQLConnection;
}
- (NSArray *)columnsForTable:(NSString *)tableName
{
	MYSQL_RES *result = mysql_list_fields(mySQLConnection, [tableName UTF8String], "%");
	if(result)
	{
		NSArray *fields = [ARMySQLField fieldsForResult:result];
		NSMutableArray *fieldNames = [NSMutableArray array];
		for(ARMySQLField *field in fields)
		{
			[fieldNames addObject:field.name];
		}
		return fieldNames;
	}
	else
		ARDebugLog(@"Couldn't get columns");
	return nil;
}
- (BOOL)beginTransaction
{
  int status = mysql_query(mySQLConnection, "START TRANSACTION");
  if(status == 0)
		return YES;
	return NO;
}
- (BOOL)endTransaction
{
  int status = mysql_query(mySQLConnection, "COMMIT");
  if(status == 0)
		return YES;
	return NO;
}
- (NSUInteger)lastInsertId
{
  return lastInsertId;
}

- (NSString *)lastErrorMessage
{
  return [NSString stringWithUTF8String:mysql_error(mySQLConnection)];
}

#pragma mark -
#pragma mark Utilities
- (NSString *)applySubstitutions:(NSDictionary *)substitutions onQuery:(NSString *)query
{
  // Apply substitutions (if any)
  NSMutableString *mutableSQL = [query mutableCopy];
  if(substitutions != nil)
  {
    NSEnumerator *keyEnum = [substitutions keyEnumerator];
    NSString *key;
    
    while(key = [keyEnum nextObject])
    {
      [mutableSQL replaceOccurrencesOfString:[NSString stringWithFormat:@":%@", key]
                                  withString:[self processArgument:[substitutions objectForKey:key]]
                                     options:0
                                       range:NSMakeRange(0, [mutableSQL length])];
    }
  }
  return [mutableSQL autorelease];
}
- (NSString *)prepareString:(NSString *)string
{
  if(!string)
    return @"NULL";
  NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
  char *buffer = calloc(sizeof(char), ([stringData length] * 2) + 1);
  //unsigned int bufferLength = mysql_real_escape_string(mySQLConnection, buffer, [stringData bytes], [stringData length]);
  //NSString *preparedString = [NSString stringWithCString:buffer length:bufferLength];
  NSString *preparedString = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
  free(buffer);
  return preparedString;
}
- (NSString *)prepareData:(NSData *)data
{
  if(!data)
    return @"NULL";
  char *buffer = calloc(sizeof(char), ([data length] * 2) + 1);
  //unsigned long bufferLength = mysql_hex_string(buffer, [data bytes], [data length]);
  //NSString *preparedString = [NSString stringWithCString:buffer length:bufferLength];
  NSString *preparedString = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
  free(buffer);
  return preparedString;
}
- (NSString *)prepareDate:(NSCalendarDate *)date
{
  return [date descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S"];
}
- (NSString *)prepareNumber:(NSNumber *)number
{
  return [number stringValue];
}
- (NSString *)processArgument:(id)argument
{
  if(!argument || [argument isKindOfClass:[NSNull class]])
    return @"NULL";
  else if([argument isKindOfClass:[NSString class]])
    return [NSString stringWithFormat:@"'%@'", [self prepareString:argument]];
  else if([argument isKindOfClass:[NSDate class]])
    return [NSString stringWithFormat:@"'%@'", [self prepareDate:argument]];
  else if([argument isKindOfClass:[NSData class]])
    return [NSString stringWithFormat:@"X'%@'", [self prepareData:argument]];
	else if([argument isKindOfClass:[NSNumber class]])
    return [NSString stringWithFormat:@"'%@'", [self prepareNumber:argument]];
  
  return nil;
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
