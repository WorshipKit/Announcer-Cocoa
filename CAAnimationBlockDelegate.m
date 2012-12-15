#import "CAAnimationBlockDelegate.h"

@implementation CAAnimationBlockDelegate : NSObject

@synthesize blockOnAnimationStarted;
@synthesize blockOnAnimationSucceeded;
@synthesize blockOnAnimationFailed;

/*
 * Delegate method called by CAAnimation at start of animation
 */
- (void) animationDidStart:(CAAnimation *)theAnimation {

    if( !self.blockOnAnimationStarted ) return;

    self.blockOnAnimationStarted();
}

/*
 * Delegate method called by CAAnimation at end of animation
 */
- (void) animationDidStop:(CAAnimation *)theAnimation
                 finished:(BOOL)flag {
    if( flag ) {
        if( !self.blockOnAnimationSucceeded ) return;
        self.blockOnAnimationSucceeded();
        return;
    }
    if( !self.blockOnAnimationFailed ) return;
    self.blockOnAnimationFailed();
}

@end