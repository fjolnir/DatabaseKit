#import "DBPointerCollectionAdditions.h"

#if __has_feature(objc_arc)
#  error "DBPointerCollectionAdditions need to be compiled with -fno-objc-arc"
#else

void *DBMapTableGet(NSMapTable *table, void *key)
{
    return (void *)[table objectForKey:key];
}
void DBMapTableInsert(NSMapTable *table, void *key, void *object)
{
    [table setObject:(id)object forKey:key];
}
void DBResetMapTable(NSMapTable *table)
{
    [table removeAllObjects];
}

void *DBHashTableGet(NSHashTable *table, void *key)
{
    return (void *)[table member:(id)key];
}
void DBHashTableInsert(NSHashTable *table, void *value)
{
    [table addObject:(id)value];
}
void DBHashTableRemove(NSHashTable *table, void *value)
{
    [table removeObject:value];
}
void DBResetHashTable(NSHashTable *table)
{
    [table removeAllObjects];
}
void DBEnumerateHashTable(NSHashTable *table, void (^enumerationBlock)(void *))
{
    NSCParameterAssert(enumerationBlock);
    for(id val in table) {
        enumerationBlock((void *)val);
    }
}
#endif
