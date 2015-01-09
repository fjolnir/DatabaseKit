#import "DBModel+JSON.h"
#import "DBUtilities.h"
#import "DBIntrospection.h"
#import "DBISO8601DateFormatter.h"

NSString * const DBDateTransformerName = @"DBDateTransformer",
         * const DBUUIDTransformerName = @"DBUUIDTransformer";

@implementation DBModel (JSON)

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    DBNotImplemented();
    return nil;
}

+ (NSValueTransformer *)JSONValueTransformerForKey:(NSString *)key
{
    NSParameterAssert(key);
    
    SEL selector = DBCapitalizedSelector(@"JSONValueTransformerFor", key);
    if([self respondsToSelector:selector]) {
        id (*imp)(id,SEL) = (void *)[self methodForSelector:selector];
        return imp(self, selector);
    } else {
        DBPropertyAttributes *attrs = DBAttributesForProperty(self, class_getProperty(self, key.UTF8String));
        Class klass = attrs->klass;
        free(attrs);
        
        if([klass isSubclassOfClass:[NSDate class]])
            return [NSValueTransformer valueTransformerForName:DBDateTransformerName];
        else if([klass isSubclassOfClass:[NSUUID class]])
            return [NSValueTransformer valueTransformerForName:DBUUIDTransformerName];
        else if([klass isSubclassOfClass:[DBModel class]])
            return [DBModelJSONTransformer transformerForModelClass:klass];
        else
            return nil;
    }
}

+ (NSArray *)objectsFromJSONArray:(NSArray *)JSONArray
{
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:JSONArray.count];
    for(NSDictionary *JSONObject in JSONArray) {
        [objects addObject:[[self alloc] initWithJSONObject:JSONObject]];
    }
    return objects;
}

- (instancetype)initWithJSONObject:(NSDictionary *)JSONObject
{
    if((self = [super init]))
        [self mergeValuesFromJSONObject:JSONObject];
    return self;
}

- (void)mergeValuesFromJSONObject:(NSDictionary *)JSONObject
{
   NSDictionary *JSONKeyPaths = [self.class JSONKeyPathsByPropertyKey];
    for(NSString *key in self.class.savedKeys) {
        NSString *JSONPath = JSONKeyPaths[key];
        if(!JSONPath)
            continue;
        
        id value = [JSONObject valueForKeyPath:JSONPath];
        if(!value || [[NSNull null] isEqual:value])
            continue;
        
        NSValueTransformer *valueTransformer = [self.class JSONValueTransformerForKey:key];
        [self setValue:valueTransformer
                       ? [valueTransformer transformedValue:value]
                       : value
                forKey:key];
    }
}

- (NSDictionary *)JSONObjectRepresentation
{
    NSMutableDictionary *obj = [NSMutableDictionary dictionaryWithCapacity:self.class.savedKeys.count];
    NSDictionary *JSONKeyPaths = [self.class JSONKeyPathsByPropertyKey];
    for(NSString *key in self.class.savedKeys) {
        NSString *keyPath = JSONKeyPaths[key];
        if(!keyPath)
            continue;
        
        NSValueTransformer *valueTransformer = [self.class JSONValueTransformerForKey:key];
        id value = [valueTransformer.class allowsReverseTransformation]
                 ? [valueTransformer reverseTransformedValue:[self valueForKey:key]]
                 : [self valueForKey:key];
        [obj setValue:value ?: NSNull.null
           forKeyPath:keyPath];
    }
    return obj;
}

@end

@implementation DBModelJSONTransformer {
    Class _klass;
}

+ (Class)transformedValueClass
{
    return [DBModel class];
}

+ (instancetype)transformerForModelClass:(Class)klass
{
    NSParameterAssert([klass isSubclassOfClass:[DBModel class]]);
    
    DBModelJSONTransformer *transformer = [self new];
    if(transformer)
        transformer->_klass = klass;
    return transformer;
}
- (id)transformedValue:(id)value
{
    NSParameterAssert([value isKindOfClass:[NSDictionary class]]);
    return [[_klass alloc] initWithJSONObject:value];
}

- (id)reverseTransformedValue:(id)value
{
    NSParameterAssert([value isKindOfClass:_klass]);
    return [value JSONObjectRepresentation];
}

@end


@interface DBDateTransformer : NSValueTransformer
@end

@implementation DBDateTransformer
+ (void)load
{
    [NSValueTransformer setValueTransformer:[self new] forName:DBDateTransformerName];
}

+ (Class)transformedValueClass
{
    return [NSDate class];
}
+ (BOOL)allowsReverseTransformation
{
    return YES;
}
+ (DBISO8601DateFormatter *)dateFormatter
{
    static DBISO8601DateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [DBISO8601DateFormatter new];
    });
    return formatter;
}
- (id)transformedValue:(id)value
{
    NSParameterAssert([value isKindOfClass:[NSString class]]);
    return [self.class.dateFormatter dateFromString:value];
}

- (id)reverseTransformedValue:(id)value
{
    NSParameterAssert([value isKindOfClass:[NSDate class]]);
    return [self.class.dateFormatter stringFromDate:value];
}
@end


@interface DBUUIDTransformer : NSValueTransformer
@end

@implementation DBUUIDTransformer
+ (void)load
{
    [NSValueTransformer setValueTransformer:[self new] forName:DBUUIDTransformerName];
}

+ (Class)transformedValueClass
{
    return [NSUUID class];
}
+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    NSParameterAssert([value isKindOfClass:[NSString class]]);
    
    if([value length] == 32)
        value = [NSString stringWithFormat:@"%@-%@-%@-%@-%@",
                 [value substringWithRange:(NSRange) { 0,  8  }],
                 [value substringWithRange:(NSRange) { 8,  4  }],
                 [value substringWithRange:(NSRange) { 12, 4  }],
                 [value substringWithRange:(NSRange) { 16, 4  }],
                 [value substringWithRange:(NSRange) { 20, 12 }]];
    
    NSUUID *UUID = [[NSUUID alloc] initWithUUIDString:value];
    if(!UUID)
        [NSException raise:NSInvalidArgumentException format:@"Invalid UUID string: %@", value];
    return UUID;
}

- (id)reverseTransformedValue:(id)value
{
    NSParameterAssert([value isKindOfClass:[NSUUID class]]);
    return [value UUIDString];
}
@end
