#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/*! @cond IGNORE */
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
    BOOL hasProtocolList;
    char encoding[];
} DBPropertyAttributes;

__attribute((overloadable)) SEL DBCapitalizedSelector(NSString *prefix, NSString *key, NSString *suffix);
__attribute((overloadable)) SEL DBCapitalizedSelector(NSString *prefix, NSString *key);

NSArray *DBClassesInheritingFrom(Class superclass);

DBPropertyAttributes *DBAttributesForProperty(Class klass, objc_property_t property);
void DBIteratePropertiesForClass(Class klass, void (^blk)(DBPropertyAttributes *));
NSArray *DBProtocolNamesInTypeEncoding(const char *encoding);
/*! @endcond */
