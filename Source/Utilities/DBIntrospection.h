#import <Foundation/Foundation.h>
#import <objc/runtime.h>

__attribute((overloadable))
SEL DBCapitalizedSelector(NSString *prefix, NSString *key, NSString *suffix);
__attribute((overloadable)) 
SEL DBCapitalizedSelector(NSString *prefix, NSString *key);

NSArray *DBClassesInheritingFrom(Class superclass);

typedef NS_ENUM(NSUInteger, DBMemoryManagementPolicy) {
    DBPropertyStrong,
    DBPropertyWeak,
    DBPropertyCopy
};

typedef struct {
    const char *name;
    Ivar ivar;
    SEL getter;
    SEL setter;
    DBMemoryManagementPolicy memoryManagementPolicy;
    BOOL dynamic;
    BOOL atomic;
    Class klass;
    char encoding[];
} DBPropertyAttributes;

DBPropertyAttributes *DBAttributesForProperty(Class klass, objc_property_t property);
void DBIteratePropertiesForClass(Class klass, void (^blk)(DBPropertyAttributes *));
