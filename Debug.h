//
//  Debug.h
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 7/4/11.
//  Copyright 2011 Fjölnir Ásgeirsson. All rights reserved.
//

#ifndef DatabaseKit_Debug_h
#define DatabaseKit_Debug_h

// Some debug stuff
// Crashesss
#define CrashHerePlease() { *(int *)0 = 123; }
#define DBLog(...) printf("%s(Active Record)[%u] %32.32s: %s\n", [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] UTF8String], \
getpid(),\
[[NSString stringWithFormat:@"%s:%u", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__] UTF8String],\
[[NSString stringWithFormat:__VA_ARGS__] UTF8String])
/*#define DBLog(...) printf("%s: %s\n", [[NSString stringWithFormat:@"%s:%u", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__] UTF8String],\
 [[NSString stringWithFormat:__VA_ARGS__] UTF8String])*/

#ifdef ENABLE_DB_DEBUG
// We make it a warning because when unit testing it's nice to see the logs in the list view instead of having to scroll through all the compiler output
#define DBDebugLog(...) printf("%s: warning: %s\n", [[NSString stringWithFormat:@"%s:%u", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__] UTF8String], [[NSString stringWithFormat:__VA_ARGS__] UTF8String])
#else
# define DBDebugLog(...) 
#endif

#endif
