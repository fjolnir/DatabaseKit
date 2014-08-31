// Base64 extensions
// Implementation borrowed from: https://github.com/mikeho/QSUtilities
#import <Foundation/Foundation.h>

@interface NSString (Base64Extensions)
- (NSData *)decodeBase64;
@end

@interface NSData (Base64Extensions)
- (NSString *)encodeBase64;
@end