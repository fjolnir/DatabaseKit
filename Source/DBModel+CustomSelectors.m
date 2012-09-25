//
//  DBModel+CustomSelectors.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 12.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import "DBModel.h"
#import "DBModelPrivate.h"
#import <objc/runtime.h>

@implementation DBModel (CustomSelectors)
- (BOOL)respondsToSelector:(SEL)aSelector
{
    NSString *attributeName;
    [DBModel typeOfSelector:aSelector attributeName:&attributeName];
    if(attributeName && [self relationshipForKey:attributeName])
        return YES;
    return [super respondsToSelector:aSelector];
}

+ (BOOL)resolveInstanceMethod:(SEL)aSEL
{
    NSString *attributeName;
    switch((int)[DBModel typeOfSelector:aSEL attributeName:&attributeName]) {
        case DBAttributeSelectorReader:
            class_addMethod([self class], aSEL, imp_implementationWithBlock(^(DBModel *self){
                return [self retrieveValueForKey:attributeName];
            }), "@@:");
            return YES;
        case DBAttributeSelectorWriter:
            class_addMethod([self class], aSEL, imp_implementationWithBlock(^(DBModel *self, id value) {
                [self sendValue:value forKey:attributeName];
            }), "v@:@");
            return YES;
        case DBAttributeSelectorAdder:
            class_addMethod([self class], aSEL, imp_implementationWithBlock(^(DBModel *self, id value) {
                [self addRecord:value forKey:attributeName];
            }), "v@:@");
            return YES;
        case DBAttributeSelectorRemover:
            class_addMethod([self class], aSEL, imp_implementationWithBlock(^(DBModel *self, id value) {
                [self removeRecord:value forKey:attributeName];
            }), "v@:@");
            return YES;
    }
    return [super resolveInstanceMethod:aSEL];
}

//- (void)forwardInvocation:(NSInvocation *)invocation
//{
//    NSString *attributeName;
//    DBAttributeSelectorType selectorType = [self typeOfSelector:[invocation selector] attributeName:&attributeName];
//
//    DBRelationship *relationship = [self relationshipForKey:attributeName];
//
//    if(relationship) {
//        // the attribute name is the key we need to set so we pass it as the 'key' argument
//        if(selectorType == DBAttributeSelectorReader) {
//            [invocation setSelector:@selector(retrieveValueForKey:)];
//            [invocation setTarget:self];
//            [invocation setArgument:&attributeName atIndex:2];
//            [invocation invoke];
//        }
//        else if(selectorType == DBAttributeSelectorWriter)
//        {
//            [invocation setSelector:@selector(setValue:forKey:)];
//            [invocation setTarget:self];
//            [invocation setArgument:&attributeName atIndex:3];
//            [invocation invoke];
//        }
//        // These add records for to-many relationships
//        else if(selectorType == DBAttributeSelectorAdder)
//        {
//            [invocation setSelector:@selector(addRecord:forKey:)];
//            [invocation setTarget:self];
//            [invocation setArgument:&attributeName atIndex:3];
//            [invocation invoke];
//        }
//        else if(selectorType == DBAttributeSelectorRemover)
//        {
//            [invocation setSelector:@selector(removeRecord:forKey:)];
//            [invocation setTarget:self];
//            [invocation setArgument:&attributeName atIndex:3];
//            [invocation invoke];
//        }
//    }
//}
//
//- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
//{
//    NSString *attributeName;
//    DBAttributeSelectorType selectorType = [self typeOfSelector:aSelector attributeName:&attributeName];
//
//    DBRelationship *relationship = [self relationshipForKey:attributeName];
//
//    NSMethodSignature *signature = nil;
//    if(relationship)
//    {
//        if(selectorType == DBAttributeSelectorReader)
//            signature = [super methodSignatureForSelector:@selector(retrieveValueForKey:)];
//        else if(selectorType == DBAttributeSelectorWriter)
//            signature = [super methodSignatureForSelector:@selector(setValue:forKey:)];
//        else if(selectorType == DBAttributeSelectorAdder)
//            signature = [super methodSignatureForSelector:@selector(addRecord:forKey:)];
//        else if(selectorType == DBAttributeSelectorRemover)
//            signature = [super methodSignatureForSelector:@selector(removeRecord:forKey:)];
//    }
//    if(signature != nil)
//        return signature;
//    else
//        return [super methodSignatureForSelector:aSelector];
//}
@end
