#import "NSObject+iPhoneHacks.h"

@implementation NSObject (NSObject_iPhoneHacks)

+ (NSString *)className {
  return NSStringFromClass(self);
}

- (NSString *)className {
  return [[self class] className];
}

@end
