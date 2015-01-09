#import <DatabaseKit/DBModel.h>

extern NSString * const DBDateTransformerName;
extern NSString * const DBUUIDTransformerName;

@interface DBModel (JSON)
@property(readonly) NSDictionary *JSONObjectRepresentation;

+ (NSDictionary *)JSONKeyPathsByPropertyKey;
+ (NSValueTransformer *)JSONValueTransformerForKey:(NSString *)key;

+ (NSArray *)objectsFromJSONArray:(NSArray *)JSONArray;
- (instancetype)initWithJSONObject:(NSDictionary *)JSONObject;
@end

@interface DBModelJSONTransformer : NSValueTransformer
+ (instancetype)transformerForModelClass:(Class)klass;
@end

