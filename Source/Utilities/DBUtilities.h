#define DBEqual(a, b) ({ \
    __typeof(a) __a = (a); \
    __typeof(b) __b = (b); \
    __a == __b || [__a isEqual:__b]; \
})

#define DBNotImplemented() \
    [NSException raise:NSInternalInconsistencyException \
                format:@"%@ not implemented for %@", \
                       NSStringFromSelector(_cmd), [self class]];
