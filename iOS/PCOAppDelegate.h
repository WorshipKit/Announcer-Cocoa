//
//  PCOAppDelegate.h
//  Announcer
//
//  Created by Jason Terhorst on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PCOAnnouncerController.h"

@interface PCOAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>
{
	PCOAnnouncerController * announcerController;
}

@property (strong, nonatomic) UIWindow *window;

@end
