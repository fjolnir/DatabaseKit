#import <unistd.h>

/*! @cond IGNORE */
#define DBEqual(a, b) ({ \
    __typeof(a) __a = (a); \
    __typeof(b) __b = (b); \
    __a == __b || [__a isEqual:__b]; \
})

#define DBNotImplemented() \
    [NSException raise:NSInternalInconsistencyException \
                format:@"%@ not implemented for %@", \
                       NSStringFromSelector(_cmd), self.class];

#define DBLog(...) printf("%s(DBKit)[%u] %s: %s\n", [[[NSProcessInfo processInfo] processName] UTF8String], \
    getpid(),\
    [[NSString stringWithFormat:@"%s:%u", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__] UTF8String],\
    [[NSString stringWithFormat:__VA_ARGS__] UTF8String])

#ifdef ENABLE_DB_DEBUG
#  define DBDebugLog(...) DBLog(__VA_ARGS__)
#else
# define DBDebugLog(...) 
#endif
/*! @endcond */
