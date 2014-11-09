#include <unistd.h>

#define DBLog(...) printf("%s(DBKit)[%u] %s: %s\n", [[[NSProcessInfo processInfo] processName] UTF8String], \
    getpid(),\
    [[NSString stringWithFormat:@"%s:%u", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__] UTF8String],\
    [[NSString stringWithFormat:__VA_ARGS__] UTF8String])

#ifdef ENABLE_DB_DEBUG
#  define DBDebugLog(...) DBLog(__VA_ARGS__)
#else
# define DBDebugLog(...) 
#endif
