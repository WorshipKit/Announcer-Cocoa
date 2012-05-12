//
//  PCOAnnouncerController.h
//  Announcer
//
//  Created by Jason Terhorst on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PCOAnnouncerMainTableViewController.h"

@interface PCOAnnouncerController : NSObject
{
	UINavigationController * mainNavigationController;
}

- (UIViewController *)viewController;

@end
