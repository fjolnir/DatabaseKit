//
//  SenTestCase+Fixtures.h
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 1.4.2008.
//  Copyright 2008 Fjölnir Ásgeirsson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GHUnit/GHUnit.h>

@class ARSQLiteConnection;
//@class ARMySQLConnection;

// Sets the sqlite database up with fixtures
@interface GHTestCase (Fixtures)
- (ARSQLiteConnection *)setUpSQLiteFixtures;
//- (ARMySQLConnection *)setUpMySQLFixtures;
@end
