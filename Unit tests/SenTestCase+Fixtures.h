//
//  SenTestCase+Fixtures.h
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 1.4.2008.
//  Copyright 2008 ninja kitten. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SenTestingKit/SenTestingKit.h>

@class ARSQLiteConnection;
@class ARMySQLConnection;

// Sets the sqlite database up with fixtures
@interface SenTestCase (Fixtures)
- (ARSQLiteConnection *)setUpSQLiteFixtures;
- (ARMySQLConnection *)setUpMySQLFixtures;
@end
