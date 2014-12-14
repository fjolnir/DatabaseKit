#import "NSString+DBAdditions.h"

#define DBEqual(a, b) ({ \
    __typeof(a) __a = (a); \
    __typeof(b) __b = (b); \
    __a == __b || [__a isEqual:__b]; \
})

__attribute__((overloadable))
static SEL DBCapitalizedSelector(NSString *prefix, NSString *key, NSString *suffix)
{
    return NSSelectorFromString([NSString stringWithFormat:@"%@%@%@",
                                 prefix, [key db_stringByCapitalizingFirstLetter], suffix ?: @""]);
}

__attribute__((overloadable))
static SEL DBCapitalizedSelector(NSString *prefix, NSString *key)
{
    return NSSelectorFromString([NSString stringWithFormat:@"%@%@",
                                 prefix, [key db_stringByCapitalizingFirstLetter]]);
}
