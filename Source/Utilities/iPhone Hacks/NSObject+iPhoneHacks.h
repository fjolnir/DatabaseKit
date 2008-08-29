//
//  NSObject+iPhoneHacks.h
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 27.8.2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//


#if (TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR)
@interface NSObject (iPhoneHacks)
+ (NSString *)classname;
- (NSString *)className;
@end
#endif