#import <DatabaseKit/DBModel.h>

extern NSString * const DBDateTransformerName;
extern NSString * const DBUUIDTransformerName;

@interface DBModel (JSON)
@property(readonly) NSDictionary *JSONObjectRepresentation;

/*!
 * Returns a dictionary of the format `"property": "JSONKey"`
 * that describes how to map a JSON object to properties. (And vice versa)
 */
+ (NSDictionary *)JSONKeyPathsByPropertyKey;
/*!
 * Returns a value transformer for converting from a JSON value to
 * whatever value type the corresponding property requires.
 * To override the value transformer for a given type you should implement
 * a method with a name of the format `JSONValueTransformerForMyKey`
 */
+ (NSValueTransformer *)JSONValueTransformerForKey:(NSString *)key;

/*!
 * Takes an array of JSON Objects, and returns an array of DBModel instances;
 */
+ (NSArray *)objectsFromJSONArray:(NSArray *)JSONArray;
/*!
 * Creates an instance and merges the values from `JSONObject`
 */
- (instancetype)initWithJSONObject:(NSDictionary *)JSONObject;

/*!
 * Merges the values contained within `JSONObject` 
 * using `JSONKeyPathsByPropertyKey` and `JSONValueTransformerForKey`.
 */
- (void)mergeValuesFromJSONObject:(NSDictionary *)JSONObject;
@end

/*!
 * Transforms JSONObjects ⇄ DBModel
 */
@interface DBModelJSONTransformer : NSValueTransformer
+ (instancetype)transformerForModelClass:(Class)klass;
@end

