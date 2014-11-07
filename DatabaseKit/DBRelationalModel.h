#import <DatabaseKit/DatabaseKit.h>

@interface DBRelationalModel : DBModel
+ (Class)relatedClassForKey:(NSString *)key isToMany:(BOOL *)outToMany;
+ (NSString *)foreignKeyName;
@end
