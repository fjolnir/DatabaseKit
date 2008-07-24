//
//  ARSQLiteConnectionTest.h
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@class ARSQLiteConnection;

@interface ARSQLiteConnectionTest : SenTestCase {
  ARSQLiteConnection *connection;
}
- (void)testConnection;
@end
