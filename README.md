 DatabaseKit ReadMe
=====================

About:
======
DatabaseKit is an unbelievably straight-forward to use database framework for Objective-C.

DatabaseKit was written by Fjölnir Ásgeirsson and is licensed under the BSD license.

Features:
=========
 * Supported databases
  - SQLite 3
  - (PostgreSQL planned for the very near future)
 * Query composition done purely in Objective-C
 * Table relationships
 * Almost no code required

Minitutorial
=============
To create a model there are 2 steps.

 * **1** Create the table in your database
 * **2** Create a model class named as the singularized version of your table name (people -> person)

**Example:**
Let's say I created a table called 'people' with 3 columns.

 * id as the primary key
 * firstName as varchar(255)
 * lastName  as varchar(255)

And loaded it using

	[DBModel setDefaultConnection:[DBConnection openConnectionWithURL:[NSURL URLWithString:@"sqlite://path"] error:&err]];

Then we'd create the following class definition:

	@interface Person : DBModel
	@end

And to prevent the compiler from complaining when we call custom accessors we also create properties
to suppress 'method missing' warnings. So the class definition will look like:

	@interface Person : DBModel
		@property(readwrite, assign) NSString *firstName, *lastName
	@end
	
and the implementation:

	@implementation Person
		@dynamic firstName, lastName
	@end

That's it. Now we can get people like so:

	DBQuery *people = [[DBTable withName:@"people"] select];

and if we want the name of the second person we could:

	Person *person = people[1];
	NSLog(@"%@ %@", person.firstName, person.lastName);

### More advanced query generation

    ARQuery *q = [[aTable select:@{ @"field1", @"field2" }] where:@{ @"id": @123 }];
    for(NSDictionary *row in [q limit:@100]) {
        NSLog(@"f1: %@", row[@"field1"]);
    }

---
    // Delete really old rows
    [[aTable delete] where:@[@"modifiedAt < ?", [NSDate distantPast]]];
---
The examples above look even nicer when written in my scripting language [Tranquil](http://github.com/fjolnir/Tranquil)

    q = (aTable select: { $field1, $field2 }) where: { $id: 123 }
    q each: `row | row print`
    
    (aTable delete) where: ["modifiedAt < ?", NSDate distantPast]
