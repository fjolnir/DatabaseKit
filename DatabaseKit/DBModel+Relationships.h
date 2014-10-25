#import <DatabaseKit/DatabaseKit.h>

@interface DBModel (Relationships)
+ (Class)relatedClassForKey:(NSString *)key;
+ (NSString *)foreignKeyName;
@end
