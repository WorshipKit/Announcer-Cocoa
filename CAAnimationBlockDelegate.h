#import <QuartzCore/QuartzCore.h>

@interface CAAnimationBlockDelegate : NSObject

// Block to call when animation is started
@property (nonatomic, strong)
void(^blockOnAnimationStarted)(void);

// Block to call when animation is successful
@property (nonatomic, strong)
void(^blockOnAnimationSucceeded)(void);

// Block to call when animation fails
@property (nonatomic, strong)
void(^blockOnAnimationFailed)(void);

/*
 * Delegate method called by CAAnimation at start of animation
 *
 * @param theAnimation animation which issued the callback.
 */
- (void)animationDidStart:(CAAnimation *)theAnimation;

/*
 * Delegate method called by CAAnimation at end of animation
 *
 * @param theAnimation animation which issued the callback.
 * @param finished BOOL indicating whether animation succeeded
 *              or failed.
 */
- (void)animationDidStop:(CAAnimation *)theAnimation
                finished:(BOOL)flag;
@end