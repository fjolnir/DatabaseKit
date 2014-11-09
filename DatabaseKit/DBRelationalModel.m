#import "DBRelationalModel.h"
#import "DBModel+Private.h"
#import "NSString+DBAdditions.h"
#import <objc/runtime.h>

@implementation DBRelationalModel {
    NSMutableDictionary *_implicitColumns;
}

+ (Class)relatedClassForKey:(NSString *)key isToMany:(BOOL *)outToMany
{
    Class klass;
    if([self typeForKey:key class:&klass] == _C_ID) {
        if([klass isSubclassOfClass:[NSSet class]]) {
            if(outToMany) *outToMany = YES;
            return NSClassFromString([[self classPrefix] stringByAppendingString:[[key singularizedString] stringByCapitalizingFirstLetter]]);
        } else if([klass isSubclassOfClass:[DBRelationalModel class]]) {
            if(outToMany) *outToMany = NO;
            return NSClassFromString([[self classPrefix] stringByAppendingString:[key stringByCapitalizingFirstLetter]]);
        }
    }
    return nil;
}

+ (NSString *)foreignKeyName
{
    return [[[self tableName] singularizedString] stringByAppendingString:@"Identifier"];
}

- (id)valueForKey:(NSString *)key
{
    id value = [super valueForKey:key];

    if(!value) {
        BOOL toMany;
        Class klass = [[self class] relatedClassForKey:key isToMany:&toMany];
        char *ivarName = property_copyAttributeValue(class_getProperty([self class], [key UTF8String]), "V");
        if(ivarName && klass) {
            DBSelectQuery *query = [self queryForRelationalKey:key];
            value = toMany ? [query execute] : [query firstObject];
            object_setIvar(self, class_getInstanceVariable([self class], ivarName), value);
            free(ivarName);
        }
    }
    return value;
}

- (id)valueForUndefinedKey:(NSString *)key
{
    if([self.table.columns containsObject:key])
        return _implicitColumns[key];
    else
        return [super valueForUndefinedKey:key];
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if([self.table.columns containsObject:key]) {
        if(!_implicitColumns)
            _implicitColumns = [NSMutableDictionary new];
        
        if(value)
            _implicitColumns[key] = value;
        else
            [_implicitColumns removeObjectForKey:key];
    } else
        [super setValue:value forKey:key];
}

- (DBWriteQuery *)saveQueryForKey:(NSString *)key
{
    BOOL toMany;
    Class relatedClass = [[self class] relatedClassForKey:key isToMany:&toMany];
    if(relatedClass) {
        if(toMany) {
            NSArray *counterparts = [self valueForKey:key];
            for(DBModel *counterpart in counterparts) {
                if(!counterpart.isInserted)
                    [counterpart save];
            }
            DBTable *counterpartTable = self.table.database[[relatedClass tableName]];
            return [[counterpartTable update:@{ [[self class] foreignKeyName]: self.identifier }]
                                       where:@"identifier IN %@", [[self valueForKey:key] valueForKey:@"identifier"]];
        } else {
            NSDictionary *value = @{ [relatedClass foreignKeyName]: [[self valueForKey:key] identifier] };
            return self.inserted ? [self.table update:value] : [self.table insert:value];
        }
        return nil;
    } else
        return [super saveQueryForKey:key];
}

- (DBSelectQuery *)queryForRelationalKey:(NSString *)key
{
    BOOL toMany;
    Class relatedClass = [[self class] relatedClassForKey:key isToMany:&toMany];
    if(relatedClass) {
        DB *db = self.table.database;
        DBTable *counterpartTable = db[[relatedClass tableName]];

        if(toMany)
            return [[counterpartTable select] where:@"%K = %@", [[self class] foreignKeyName], self.identifier];
        else
            return [[counterpartTable select] where:@"identifier = %@", [self valueForKey:[key stringByAppendingString:@"Identifier"]]];
    }
    return nil;
}

@end
