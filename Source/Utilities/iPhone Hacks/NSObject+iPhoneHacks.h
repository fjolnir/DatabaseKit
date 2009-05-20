//
//  NSObject+iPhoneHacks.h
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 27.8.2008.
//  Copyright 2008 ninja kitten. All rights reserved.
//


#if (TARGET_OS_IPHONE)
@interface NSObject (iPhoneHacks)
+ (NSString *)className;
- (NSString *)className;
@end
#endif
