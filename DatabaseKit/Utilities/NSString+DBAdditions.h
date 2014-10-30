#import <Foundation/Foundation.h>

@interface NSString (DBAdditions)
/*! Returns a singularized form of the string */
- (NSString *)pluralizedString;
/*! Returns a pluralized form of the string */
- (NSString *)singularizedString;

/*! Returns a copy of the string with the first letter capitalized */
- (NSString *)stringByCapitalizingFirstLetter;
/*! Returns a copy of the string with the first letter cdeapitalized */
- (NSString *)stringByDecapitalizingFirstLetter;

/*! Converts a camelized string to a underscored one aString -> a_string */
- (NSString *)underscoredString;
/*! Converts an underscored string to a cameilzed one a_string -> aString */
- (NSString *)camelizedString;

/*! Just returns self */
- (NSString *)toString;
@end
