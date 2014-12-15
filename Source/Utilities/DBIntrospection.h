//
//  DBIntrospection.m
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 12/15/14.
//
//

#import <Foundation/Foundation.h>

__attribute((overloadable))
SEL DBCapitalizedSelector(NSString *prefix, NSString *key, NSString *suffix);
__attribute((overloadable)) 
SEL DBCapitalizedSelector(NSString *prefix, NSString *key);

NSArray *DBClassesInheritingFrom(Class superclass);
