//
//  ARBase-KeyAndSelectorParsers.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

// These methods are described in ARBase.m
// (Basically they just parse selectors(like 'setAttribute:' or simply 'attribute')
//  or keys and return what relationships they represent)
#import "ARBase.h"
#import "ARBasePrivate.h"
#import "NSString+Inflections.h"
#import "ARRelationship.h"

@implementation ARBase (KeyAndSelectorParsers)
- (ARAttributeSelectorType)typeOfSelector:(SEL)aSelector
                            attributeName:(NSString **)outAttribute
{
    NSString *selector = NSStringFromSelector(aSelector);   
    NSScanner *scanner = [NSScanner scannerWithString:selector];
    ARAttributeSelectorType selectorType;
    NSString *type;
  // Scan up to the first uppercase character to figure out what sort of action we're dealing with
    if([scanner scanUpToCharactersFromSet:[NSCharacterSet uppercaseLetterCharacterSet] intoString:&type])
    {
        if([type isEqualToString:@"set"])
            selectorType = ARAttributeSelectorWriter;
        else if([type isEqualToString:@"add"])
            selectorType = ARAttributeSelectorAdder;
        else if([type isEqualToString:@"remove"])
            selectorType = ARAttributeSelectorRemover;
        else
        {
            selectorType = ARAttributeSelectorReader;
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
        selectorType = ARAttributeSelectorReader;
        if(outAttribute != NULL)
            *outAttribute = selector;
    }
    return selectorType;
}
- (ARRelationship *)relationshipForKey:(NSString *)key
{
  for(ARRelationship *relationship in self.relationships)
  {
    if([relationship respondsToKey:key])
      return relationship;
  }
  return nil;
}
@end
