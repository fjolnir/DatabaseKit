#import <DatabaseKit/DatabaseKit.h>

@class DBSelectQuery;

@interface DBRelationalModel : DBModel
+ (Class)relatedClassForKey:(NSString *)key isToMany:(BOOL *)outToMany;
+ (NSString *)foreignKeyName;

- (DBSelectQuery *)queryForRelationalKey:(NSString *)key;
@end
