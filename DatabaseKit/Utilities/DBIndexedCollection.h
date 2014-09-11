#import <Foundation/Foundation.h>

@protocol DBIndexedCollection <NSFastEnumeration, NSObject>
- (id)objectAtIndex:(NSUInteger)index;
- (void)setObject:(id)object atIndex:(NSUInteger)idx;

- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)idx;
@end
@protocol DBKeyedCollection <NSFastEnumeration, NSObject>
- (id)objectForKey:(id<NSCopying>)key;
- (void)setObject:(id)object forKey:(id<NSCopying>)key;

- (id)objectForKeyedSubscript:(id<NSCopying>)key;
- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)key;
@end

@interface NSArray (DBKit) <DBIndexedCollection>
@end
@interface NSOrderedSet (DBKit) <DBIndexedCollection>
@end
@interface NSPointerArray (DBKit) <DBIndexedCollection>
@end

@interface NSDictionary (DBKit) <DBKeyedCollection>
@end
@interface NSMapTable (DBKit) <DBKeyedCollection>
@end