 DatabaseKit ReadMe
=====================

About:
======
DatabaseKit is an unbelievably straight-forward to use database framework for Objective-C.

Features:
=========
 * Supported databases
  - SQLite 3
  - PostgreSQL
  - And adding support for additional databases is very straightforward.
 * Query composition done purely in Objective-C.
 * If you use a connection pool(Done transparently by default) then query objects are thread safe.
 * If you provide a model class, then results from it's corresponding table will automatically be returned as instances of that class.
 * Almost no code required.

Examples
=============

### Connecting:

    // Open a SQLite database
    DB *db = [DB withURL:[NSURL URLWithString:@"sqlite://myDb.sqlite"]];

    // Alternatively; to open a Postgres database (This time with error handling)    
    NSURL *pgURL = [NSURL URLWithString:@"postgres://username:password@server/database"];
    NSError *err = nil;
    DB *db = [DB withURL:pgURL error:&err];
    if(err)
        NSLog(@"Error connecting to %@: %@", pgURL, [err localizedDescription]);

---

### Querying:

    // Get the names of every person in our database
    DBTable *people = db[@"people"];
    ARQuery *names = [people select:@"name"];
    
    for(NSDictionary *row in [names limit:@100]) {
        NSLog(@"Name: %@", row[@"name"]);
    }

---
    // Delete really old people
    [[people delete] where:@"bornOn < %@", [NSDate distantPast]];
---
    // Change the name of everyone called John
    [[[people update:@{ @"name": @"Percie" }] where:@"name = %@", @"John"] execute];
--- 
    // You can create a class to represent results from a table like so:
    [DBModel setClassPrefix:@"Nice"]; // You'd set this to whatever prefix you're using
    
    @interface NicePerson : DBModel
    @property(readwrite, retain) NSString *name, *address;
    - (void)introduceYourself;
    @end
    
    @implementation NicePerson
    - (void)introduceYourself
    {
        NSLog(@"Hi! I'm %@.", self.name);
    }
    @end
    
    // And now if you perform a query
    NicePerson *someone = [[people select] firstObject];
    [someone introduceYourself];
