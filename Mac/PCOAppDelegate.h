//
//  PCOAppDelegate.h
//  Announcer Mac
//
//  Created by Jason Terhorst on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <UIKit/UIKit.h>
#import <UIKit/UIKitView.h>

#import "PCOAnnouncerController.h"

@interface PCOAppDelegate : NSObject <NSApplicationDelegate>
{
	PCOAnnouncerController * announcerController;
}

@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet UIKitView * mainUIKitView;

@end
