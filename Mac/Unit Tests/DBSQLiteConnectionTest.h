//
//  DBSQLiteConnectionTest.h
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import <GHUnit/GHUnit.h>

@class DBConnection;

@interface DBSQLiteConnectionTest : GHTestCase {
  DBConnection *connection;
}
- (void)testConnection;
@end
