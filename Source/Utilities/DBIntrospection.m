#import "DBIntrospection.h"
#import "NSString+DBAdditions.h"
#import <objc/runtime.h>

__attribute((overloadable))
SEL DBCapitalizedSelector(NSString *prefix, NSString *key, NSString *suffix)
{
    return NSSelectorFromString([NSString stringWithFormat:@"%@%@%@",
                                 prefix, [key db_stringByCapitalizingFirstLetter], suffix ?: @""]);
}

__attribute((overloadable))
SEL DBCapitalizedSelector(NSString *prefix, NSString *key)
{
    return NSSelectorFromString([NSString stringWithFormat:@"%@%@",
                                 prefix, [key db_stringByCapitalizingFirstLetter]]);
}

NSArray *DBClassesInheritingFrom(Class superclass)
{
    int numClasses = objc_getClassList(NULL, 0);
    Class allClasses[numClasses];
    objc_getClassList(allClasses, numClasses);

    NSMutableArray *classes = [NSMutableArray array];
    for(NSInteger i = 0; i < numClasses; i++) {
        Class kls = allClasses[i];
        const char *name = class_getName(kls);
        if(!name || name[0] < 'A' || name[0] > 'Z' || strncmp(name, "NSKVONotifying_", 15) == 0)
            continue;
        do {
            kls = class_getSuperclass(kls);
        } while(kls && kls != superclass);
        if(kls)
            [classes addObject:allClasses[i]];
    }
    return [classes count] > 0
         ? classes
         : nil;
}
