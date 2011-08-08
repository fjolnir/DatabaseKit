//
//  ARSQLiteConnectionTest.h
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import <GHUnit/GHUnit.h>

@class ARSQLiteConnection;

@interface ARSQLiteConnectionTest : GHTestCase {
  ARSQLiteConnection *connection;
}
- (void)testConnection;
@end
