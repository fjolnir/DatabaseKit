//
//  ARMySQLField.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 25.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import "ARMySQLField.h"
#import "mysql_com.h"

@implementation ARMySQLField
@synthesize field;
@dynamic name;

+ (NSArray *)fieldsForResult:(MYSQL_RES *)aResult
{
  MYSQL_FIELD *aField;
  unsigned int numFields = mysql_num_fields(aResult);
  NSMutableArray *fields = [NSMutableArray arrayWithCapacity:numFields];
  while(aField = mysql_fetch_field(aResult))
  {
    [fields addObject:[self fieldWithField:aField]];
  }
  return fields;
  
}
+ (ARMySQLField *)fieldWithField:(MYSQL_FIELD *)aField
{
  return [[[self alloc] initWithField:aField] autorelease];
}
- (id)initWithField:(MYSQL_FIELD *)aField
{
  if(![super init])
    return nil;
  self.field = aField;
  
  return self;
}

- (int)type
{
  return field->type;
}
- (unsigned long)maxLength
{
  return field->max_length;
}
- (unsigned int)flags
{
  return field->flags;
}
- (NSString *)name
{
  return [NSString stringWithFormat:@"%s", field->name];
}

- (id)objectForData:(char *)inData length:(unsigned long)length
{
  if(inData == NULL)
    return [NSNull null];
  char *data = calloc(sizeof(char *), length + 1);
  memcpy(data, inData, length);
  data[length] = '\0';
  
  // The code below was pretty much ripped from MCPKit
  id object;
  switch(self.type)
  {
    case FIELD_TYPE_TINY:
    case FIELD_TYPE_SHORT:
    case FIELD_TYPE_INT24:
    case FIELD_TYPE_LONG:
      object = (self.flags & UNSIGNED_FLAG) ? [NSNumber numberWithUnsignedLong:strtoul(data, NULL, 0)] : [NSNumber numberWithLong:strtol(data, NULL, 0)];
      break;
    case FIELD_TYPE_LONGLONG:
      object = (self.flags & UNSIGNED_FLAG) ? [NSNumber numberWithUnsignedLongLong:strtoull(data, NULL, 0)] : [NSNumber numberWithLongLong:strtoll(data, NULL, 0)];
    case FIELD_TYPE_DECIMAL:
      object = [NSDecimalNumber decimalNumberWithString:[NSString stringWithUTF8String:data]];
      break;
    case FIELD_TYPE_FLOAT:
      object = [NSNumber numberWithFloat:atof(data)];
      break;
    case FIELD_TYPE_DOUBLE:
      object = [NSNumber numberWithDouble:atof(data)];
      break;
    case FIELD_TYPE_TIMESTAMP:
      // Indeed one should check which format it is (14,12...2) and get the corresponding format string
      // a switch on theLength[i] would do that...
      // Here it will crash if it's not default presentation : TIMESTAMP(14)
      // TODO: Support the timezone stored on the server
      object = [NSCalendarDate dateWithString:[NSString stringWithFormat:@"%@ GMT", [NSString stringWithUTF8String:data]] 
                                             calendarFormat:@"%Y-%m-%d %H:%M:%S %Z"];
      [object setCalendarFormat:@"%Y-%m-%d %H:%M:%S"];
      break;
    case FIELD_TYPE_DATE:
      object = [NSCalendarDate dateWithString:[NSString stringWithCString:data] calendarFormat:@"%Y-%m-%d"];
      [object setCalendarFormat:@"%Y-%m-%d"];
      break;
    case FIELD_TYPE_TIME:
      // Pass them back as string for the moment... no TIME object in Cocoa (so far)
      object = [NSString stringWithUTF8String:data];
      break;
    case FIELD_TYPE_DATETIME:
      object = [NSCalendarDate dateWithString:[NSString stringWithCString:data] calendarFormat:@"%Y-%m-%d %H:%M:%S"];
      [object setCalendarFormat:@"%Y-%m-%d %H:%M:%S"];
      break;
    case FIELD_TYPE_YEAR:
      object = [NSCalendarDate dateWithString:[NSString stringWithCString:data] calendarFormat:@"%Y"];
      [object setCalendarFormat:@"%Y"];
      break;
    case FIELD_TYPE_VAR_STRING:
    case FIELD_TYPE_STRING:
      object = [NSString stringWithUTF8String:data];
      break;
    case FIELD_TYPE_TINY_BLOB:
    case FIELD_TYPE_BLOB:
    case FIELD_TYPE_MEDIUM_BLOB:
    case FIELD_TYPE_LONG_BLOB:
      object = [NSData dataWithBytes:data length:length];
      if(!(self.flags & BINARY_FLAG)) // It is TEXT and NOT BLOB...
        object = [[[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding] autorelease];
      break;
    case FIELD_TYPE_SET:
      object = [NSString stringWithUTF8String:data];
      break;
    case FIELD_TYPE_ENUM:
      object = [NSString stringWithUTF8String:data];
      break; 
    case FIELD_TYPE_NULL:
      object = [NSNull null];
      break;
    case FIELD_TYPE_NEWDATE:
      // Don't know what the format for this type is...
      object = [NSString stringWithUTF8String:data];
      break;
    default:
      ARLog(@"in objectForData:length: Unknown type : %d, returning NSData", self.type);
      object = [NSData dataWithBytes:data length:length];
      break;
  }
  free(data);
  return !object ? [NSNull null] : object;
}

#pragma mark -
#pragma mark Cosmetics
- (NSString *)description
{
  NSMutableString *description = [NSMutableString stringWithFormat:@"MySQLColumn <0x%x> {\n", self];
  [description appendFormat:@"name: %@\n", self.name];
  [description appendFormat:@"type: %d\n", self.type];
  [description appendFormat:@"maxLength: %d\n", self.maxLength];
  [description appendString:@"}"];
  return description;
}
@end
