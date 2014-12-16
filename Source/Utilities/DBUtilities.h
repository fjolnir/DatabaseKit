#define DBOverloadable __attribute((overloadable))

#define DBEqual(a, b) ({ \
    __typeof(a) __a = (a); \
    __typeof(b) __b = (b); \
    __a == __b || [__a isEqual:__b]; \
})
