 ActiveRecord ReadMe
=====================

About:
======
ActiveRecord is an insanely easy to use database framework written in objective-c
It's obviously "inspired" by (copying) the infamous ActiveRecord that comes with Rails(http://rubyonrails.org)
But it tries to be more versatile when it comes to working with multiple connections.

I'm not very good at writing these things so consult the docs/tutorials/whatever for more info. (scroll down!)

ActiveRecord was written by ninja kitten (http://ninjakitten.us) and is licensed with the BSD license.

Features:
=========
 * Supported databases
  - SQLite 3
  - MySQL 5.0
 * Supported relationships
  - Has many
  - Has one
  - Has and belongs to many
  - Belongs to
 * Almost no code required

Using on iPhone:
====================
Building for iPhone is rather simple.
* **Step 1:**
 * Check out the latest code
 * Build for mac os x
This will create a directory called 'iPhone Headers' which contains all the headers you need (Add it to your project's header search path)

* **Step 2:**
Go ahead and add the "Source" directory to your project/target.

* **Step 3:**
Add the Inflection files to your project's "Resources" group. The Inflection files are:
	* irregulars.plist
	* plurals.plist
	* singulars.plist
	* uncountables.plist

Now you should be able to use ActiveRecord just like you would on a mac (Except without MySQL support).

Minitutorial
=============
To create a model there are 2 steps.
* **1** Create the table in your database
* **2** Create a model class named as the singularized version of your table name (people -> person)

**Example:**
Let's say I created a table called 'people' with 3 columns.
 - id as the primary key
 - firstName as varchar(255)
 - lastName  as varchar(255)
Then we'd create the following class definition:

@interface Person : ARBase
@end

And to prevent the compiler from complaining when we call custom accessors we also create a category
to suppress 'method missing' warnings. Like so:
	@interface Person (Accessors)
	- firstName;
	- setFirstName:(id)value;
	- lastName;
	- setLastName:(id)value;
	@end

and that's it. Now we can get people like so:
	NSArray *people = [Person find:ARFindAll];

and if we want the name of the second person we could:
	Person *person = [people objectAtIndex:1];
	NSLog(@"%@ %@", [person firstName], [person lastName]);

Contributing:
=============
If you wish to send patches you can email them to fjolnir@gmail.com

When writing patches please keep in mind the existing coding style
Here's most of it:

	- (id)aMethod:(int)argument
	{
	  int myVar = 123;
	  if(myVar != 123)
	    NSLog(@"impossible!");
	  else
	  {
	    NSLog(@"Very possible..");
	    // More lines of code!
	  }
	}