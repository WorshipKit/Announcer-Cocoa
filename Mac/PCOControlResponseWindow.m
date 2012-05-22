//
//  WKControlResponseWindow.m
//  Presenter
//
//  Created by Jason Terhorst on 8/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#if !TARGET_OS_IPHONE

#import "PCOControlResponseWindow.h"

@implementation PCOControlResponseWindow

@synthesize keyPressDelegate;

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)canBecomeKeyWindow;
{
	return YES;
}

- (BOOL)canBecomeMainWindow;
{
	return YES;
}

- (void)keyDown:(NSEvent *)e
{
	// every app with eye candy needs a slow mode invoked by the shift key
    //	if ([e modifierFlags] & (NSAlphaShiftKeyMask|NSShiftKeyMask))
	//	[CATransaction setValue:[NSNumber numberWithFloat:2.0f] forKey:@"animationDuration"];
	
	switch ([e keyCode])
    {
		case 123:				/* LeftArrow */
			[keyPressDelegate leftArrowPressed];
			break;
		case 124:				/* RightArrow */
			[keyPressDelegate rightArrowPressed];
			break;
		case 125:				/* Up */
			[keyPressDelegate upArrowPressed];
			break;
		case 126:				/* Down */
			[keyPressDelegate downArrowPressed];
			break;
		case 36:				/* RET */
			[keyPressDelegate returnKeyPressed];
			break;
		case 49:
			[keyPressDelegate spaceBarPressed];
			break;
		case 53:
			[keyPressDelegate escapeKeyPressed];
			break;
		default:
			NSLog (@"unhandled key event: %d\n", [e keyCode]);
			[super keyDown:e];
    }
}

@end

#endif
