#import <Foundation/Foundation.h>

void *DBMapTableGet(NSMapTable *table, void *key);
void DBMapTableInsert(NSMapTable *table, void *key, void *value);
void DBResetMapTable(NSMapTable *table);

void *DBHashTableGet(NSHashTable *table, void *key);
void DBHashTableInsert(NSHashTable *table, void *value);
void DBHashTableRemove(NSHashTable *table, void *value);
void DBResetHashTable(NSHashTable *table);
void DBEnumerateHashTable(NSHashTable *table, void (^enumerationBlock)(void *));
