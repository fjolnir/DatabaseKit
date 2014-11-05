#import <DatabaseKit/DatabaseKit.h>

@interface DBModel (Relationships)
+ (Class)relatedClassForKey:(NSString *)key isToMany:(BOOL *)outToMany;
+ (NSString *)foreignKeyName;
@end
