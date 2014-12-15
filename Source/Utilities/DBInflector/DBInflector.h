#import <Foundation/Foundation.h>

/*!
 * Provides inflections for english words (can be extended to support other languages
 * by writing a plist configuration for it)
 */
@interface DBInflector : NSObject {
  NSCache *singularCache, *pluralCache;
}
@property(readwrite, strong) NSSet *uncountables;
@property(readwrite, strong) NSArray *irregulars, *plurals, *singulars;

/*! Returns the shared inflector object */
+ (DBInflector *)sharedInflector;

/*!
 * Returns a pluralized form of a word, if it's already pluralized no change occurs
 * @param word The word to transform
 */
- (NSString *)pluralizeWord:(NSString *)word;
/*!
 * Returns a singularized form of a word, if it's already singularized no change occurs
 * @param word The word to transform
 */
- (NSString *)singularizeWord:(NSString *)word;
@end
