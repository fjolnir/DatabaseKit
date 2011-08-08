# Building ActiveRecord on iOS

Thanks to iOS's lack of support for frameworks, the initial set up of ActiveRecord on is a bit non-trivial. However, once you know the steps it's really simple. This is what you have to do:

## Adding ActiveRecord to your project
* Clone the ActiveRecord repository to the root of your project folder
* Drag the ActiveRecord project file into your application's project to create a reference
* Drag the 'Inflections' group from the 'Resources' group under the ActiveRecord.xcodeproje entry in your sourcelist over to your resource group (Typically 'Supporting Files')

Now ActiveRecord has been successfully added to your project, but you still need to add it to your target.

## Adding ActiveRecord to your target
* Select your project entry in Xcode's source list and choose your target
* Select the 'Build Phases' tab
 * Under 'Target Dependencies' add the 'iPhone Library' target from ActiveRecord
 * From the 'Products' group under ActiveRecord.xcodeproj drag 'libactive_record.a' to 'Link Binary With Libraries'
 * Add the libraries 'libsqlite3.dylib' & 'libicucore.dylib' to the 'Link Binary With Libraries' phase
* Select the 'Build Settings' tab
 * Find the 'Other Linker Flags' entry and add '-ObjC' to it (This makes sure your application loads all the Objective-C symbols from the static library including things like categories)
 * Find the 'Header Search Paths' entry and add 'activerecord/build/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)/include' (If you didn't clone ActiveRecord to the root of your project folder you'll have to update the path as necessary)

## Now it should build!

To include ActiveRecord into your source files, just include it with #import &lt;ActiveRecord/ActiveRecord.h&gt; and use it as you would the mac framework