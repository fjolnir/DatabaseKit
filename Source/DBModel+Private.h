#import <DatabaseKit/DBModel.h>
#import <DatabaseKit/DBIntrospection.h>

/*! @cond IGNORE */
@interface DBModel ()
@property(readwrite, strong) DB *database;
@property(readwrite, strong) NSUUID *savedUUID;
@property(readonly) NSDictionary *pendingQueries;

+ (NSString *)joinTableNameForKey:(NSString *)key;
+ (BOOL)_attributeIsRelationship:(DBPropertyAttributes *)attributes
                        isPlural:(BOOL *)outIsPlural
                    relatedClass:(Class *)outClass;

- (instancetype)initWithDatabase:(DB *)aDB result:(DBResult *)result;
- (BOOL)_executePendingQueries:(NSError **)outErr;
@end
/*! @endcond */
