//
//  SenTestCase+Fixtures.h
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 1.4.2008.
//  Copyright 2008 Fjölnir Ásgeirsson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DB;

DB *DBSQLiteDatabaseForTesting();
DB *DBPostgresDatabaseForTesting();