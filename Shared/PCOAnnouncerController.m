//
//  PCOAnnouncerController.m
//  Announcer
//
//  Created by Jason Terhorst on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PCOAnnouncerController.h"

@implementation PCOAnnouncerController

- (id)init;
{
	self = [super init];
	if (self)
	{
		PCOAnnouncerMainTableViewController * mainTableController = [[PCOAnnouncerMainTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
		
		mainNavigationController = [[UINavigationController alloc] initWithRootViewController:mainTableController];
		
		
	}
	
	return self;
}

- (UIViewController *)viewController;
{
	return mainNavigationController;
}

@end
