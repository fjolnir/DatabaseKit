//
//  ARBase+CustomSelectors.m
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 12.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import "ARBase.h"
#import "ARBasePrivate.h"

@implementation ARBase (CustomSelectors)
- (BOOL)respondsToSelector:(SEL)aSelector
{
  NSString *attributeName;
  [self typeOfSelector:aSelector attributeName:&attributeName];
  if(attributeName && [self relationshipForKey:attributeName])
    return YES;
  return [super respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
  NSString *attributeName;
  ARAttributeSelectorType selectorType = [self typeOfSelector:[invocation selector] 
																								attributeName:&attributeName];

  ARRelationship *relationship = [self relationshipForKey:attributeName];
	
  if(relationship)
  {
    // the attribute name is the key we need to set so we pass it as the 'key' argument
    if(selectorType == ARAttributeSelectorReader)
    {
      [invocation setSelector:@selector(retrieveValueForKey:)];
      [invocation setTarget:self];
      [invocation setArgument:&attributeName atIndex:2];
      [invocation invoke];
    }
    else if(selectorType == ARAttributeSelectorWriter)
    {
      [invocation setSelector:@selector(setValue:forKey:)];
      [invocation setTarget:self];
      [invocation setArgument:&attributeName atIndex:3];
      [invocation invoke];
    }
    // These add records for to-many relationships
    else if(selectorType == ARAttributeSelectorAdder)
    {
      [invocation setSelector:@selector(addRecord:forKey:)];
      [invocation setTarget:self];
      [invocation setArgument:&attributeName atIndex:3];
      [invocation invoke];
    }
    else if(selectorType == ARAttributeSelectorRemover)
    {
      [invocation setSelector:@selector(removeRecord:forKey:)];
      [invocation setTarget:self];
      [invocation setArgument:&attributeName atIndex:3];
      [invocation invoke];
    }
  }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
  NSString *attributeName;
  ARAttributeSelectorType selectorType = [self typeOfSelector:aSelector attributeName:&attributeName];
  
  ARRelationship *relationship = [self relationshipForKey:attributeName];

  NSMethodSignature *signature = nil;
  if(relationship)
  {
    if(selectorType == ARAttributeSelectorReader)
      signature = [super methodSignatureForSelector:@selector(retrieveValueForKey:)];
    else if(selectorType == ARAttributeSelectorWriter)
      signature = [super methodSignatureForSelector:@selector(setValue:forKey:)];
    else if(selectorType == ARAttributeSelectorAdder)
      signature = [super methodSignatureForSelector:@selector(addRecord:forKey:)];
    else if(selectorType == ARAttributeSelectorRemover)
      signature = [super methodSignatureForSelector:@selector(removeRecord:forKey:)];
  }
  if(signature != nil)
    return signature;
  else
    return [super methodSignatureForSelector:aSelector];
}
@end
