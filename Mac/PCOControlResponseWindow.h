//
//  WKControlResponseWindow.h
//  Presenter
//
//  Created by Jason Terhorst on 8/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#if !TARGET_OS_IPHONE

#import <AppKit/AppKit.h>

@class PCOControlResponseWindow;

@protocol PCOControlResponseWindowDelegate <NSObject>

- (void)leftArrowPressed;
- (void)rightArrowPressed;
- (void)upArrowPressed;
- (void)downArrowPressed;
- (void)spaceBarPressed;
- (void)returnKeyPressed;
- (void)escapeKeyPressed;

@end


@interface PCOControlResponseWindow : NSWindow
{
    //id<PCOControlResponseWindowDelegate> keyPressDelegate;
}

@property (assign) id<PCOControlResponseWindowDelegate> keyPressDelegate;

@end

#endif