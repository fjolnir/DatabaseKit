#include <unistd.h>

// Some debug stuff
// Crashesss
#define CrashHerePlease() { *(int *)0 = 123; }
#define DBLog(...) printf("%s(DBKit)[%u] %s: %s\n", [[[NSProcessInfo processInfo] processName] UTF8String], \
    getpid(),\
    [[NSString stringWithFormat:@"%s:%u", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__] UTF8String],\
    [[NSString stringWithFormat:__VA_ARGS__] UTF8String])

#ifdef ENABLE_DB_DEBUG
// We make it a warning because when unit testing it's nice to see the logs in the list view instead of having to scroll through all the compiler output
#define DBDebugLog(...) printf("%s: warning: %s\n", [[NSString stringWithFormat:@"%s:%u", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__] UTF8String], [[NSString stringWithFormat:__VA_ARGS__] UTF8String])
#else
# define DBDebugLog(...) 
#endif
