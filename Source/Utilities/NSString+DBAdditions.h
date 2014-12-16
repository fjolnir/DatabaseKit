#import <Foundation/Foundation.h>
#import "DBSQLRepresentable.h"

@interface NSString (DBAdditions) <DBSQLRepresentable>
/*! Returns a singularized form of the string */
- (NSString *)db_pluralizedString;
/*! Returns a pluralized form of the string */
- (NSString *)db_singularizedString;

/*! Returns a copy of the string with the first letter capitalized */
- (NSString *)db_stringByCapitalizingFirstLetter;
/*! Returns a copy of the string with the first letter decapitalized */
- (NSString *)db_stringByDecapitalizingFirstLetter;
@end
