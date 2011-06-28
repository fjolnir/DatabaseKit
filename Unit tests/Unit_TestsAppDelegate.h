//
//  Unit_TestsAppDelegate.h
//  Unit Tests
//
//  Created by Fjölnir Ásgeirsson on 6/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Unit_TestsAppDelegate : NSObject <NSApplicationDelegate> {
  NSWindow *_window;
}

@property (strong) IBOutlet NSWindow *window;

@end
