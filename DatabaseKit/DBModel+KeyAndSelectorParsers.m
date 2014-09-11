//
//  DBModel-KeyAndSelectorParsers.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

// These methods are described in DBModel.m
// (Basically they just parse selectors(like 'setAttribute:' or simply 'attribute')
//  or keys and return what relationships they represent)
#import "DBModel.h"
#import "DBModel+Private.h"
#import "Utilities/NSString+DBAdditions.h"
#import "Relationships/DBRelationship.h"

@implementation DBModel (KeyAndSelectorParsers)
+ (DBAttributeSelectorType)typeOfSelector:(SEL)aSelector
                            attributeName:(NSString **)outAttribute
{
    NSString *selector = NSStringFromSelector(aSelector);   
    NSScanner *scanner = [NSScanner scannerWithString:selector];
    DBAttributeSelectorType selectorType;
    NSString *type;
    // Scan up to the first uppercase character to figure out what sort of action we're dealing with
    if([scanner scanUpToCharactersFromSet:[NSCharacterSet uppercaseLetterCharacterSet] intoString:&type])
    {
        if([type isEqualToString:@"set"])
            selectorType = DBAttributeSelectorWriter;
        else if([type isEqualToString:@"add"])
            selectorType = DBAttributeSelectorAdder;
        else if([type isEqualToString:@"remove"])
            selectorType = DBAttributeSelectorRemover;
        else
        {
            selectorType = DBAttributeSelectorReader;
            [scanner setScanLocation:0];
        }
        // Prepare the attribute name for output
        if(outAttribute != NULL)
        {
          // Make the first char lowercase
          NSString *attribute = [selector substringFromIndex:[scanner scanLocation]];
          NSString *firstChar = [attribute substringToIndex:1];
          attribute = [attribute stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
          attribute = [attribute stringByReplacingOccurrencesOfString:@":" withString:@""];
          *outAttribute = attribute;
        }
    }
    else
    {
        selectorType = DBAttributeSelectorReader;
        if(outAttribute != NULL)
            *outAttribute = selector;
    }
    return selectorType;
}
- (DBRelationship *)relationshipForKey:(NSString *)key
{
  for(DBRelationship *relationship in self.relationships)
  {
    if([relationship respondsToKey:key])
      return relationship;
  }
  return nil;
}
@end
