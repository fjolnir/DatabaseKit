//
//  SenTestCase+Fixtures.h
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 1.4.2008.
//  Copyright 2008 Fjölnir Ásgeirsson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GHUnit/GHUnit.h>

@class DBConnection;

// Sets the sqlite database up with fixtures
@interface GHTestCase (Fixtures)
- (DBConnection *)setUpSQLiteFixtures;
//- (DBMySQLConnection *)setUpMySQLFixtures;
@end
