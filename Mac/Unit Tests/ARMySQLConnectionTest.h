//
//  ARMySQLConnectionTest.h
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 18.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import <GHUnit/GHUnit.h>

@class ARMySQLConnection;

@interface ARMySQLConnectionTest : SenTestCase {
  ARMySQLConnection *connection;
}
@property(readwrite, retain) ARMySQLConnection *connection;
@end
