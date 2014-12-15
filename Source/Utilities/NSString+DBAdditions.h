#import <Foundation/Foundation.h>

@interface NSString (DBAdditions)
/*! Returns a singularized form of the string */
- (NSString *)db_pluralizedString;
/*! Returns a pluralized form of the string */
- (NSString *)db_singularizedString;

/*! Returns a copy of the string with the first letter capitalized */
- (NSString *)db_stringByCapitalizingFirstLetter;
/*! Returns a copy of the string with the first letter cdeapitalized */
- (NSString *)db_stringByDecapitalizingFirstLetter;

/*! Converts a camelized string to a underscored one aString -> a_string */
- (NSString *)db_underscoredString;
/*! Converts an underscored string to a cameilzed one a_string -> aString */
- (NSString *)db_camelizedString;

/*! Just returns self */
- (NSString *)toString;
@end
