//
//  CCTouchFingerView.m
//  CCDebugTool
//
//  Created by CC on 2019/11/11.
//  Copyright © 2019 CC. All rights reserved.
//

#import "CCTouchFingerView.h"


CGFloat const CCDefaultMaxFingerRadius = 22.0;
CGFloat const CCDefaultForceTouchScale = 1.5;

@interface CCTouchFingerView ()

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CATransform3D touchEndTransform;
@property (nonatomic, assign) CGFloat touchEndAnimationDuration;
@property (nonatomic, strong) UITouch *touch;
@property (nonatomic, assign) CGPoint lastScale;

@end


@implementation CCTouchFingerView

- (instancetype)initWithPoint:(CGPoint)point
{
    if ((self = [super initWithFrame:CGRectMake(point.x - CCDefaultMaxFingerRadius, point.y - CCDefaultMaxFingerRadius, 2 * CCDefaultMaxFingerRadius, 2 * CCDefaultMaxFingerRadius)])) {
        self.opaque = NO;
        self.color = [UIColor colorWithRed:0.0 green:0.478431 blue:1.0 alpha:1.0];
        self.backgroundColor = [self.color colorWithAlphaComponent:0.4];
        self.layer.cornerRadius = CCDefaultMaxFingerRadius;
        self.layer.borderWidth = 2.0f;
        self.touchEndAnimationDuration = 0.5f;
        self.lastScale = CGPointMake(1.0, 1.0);
        self.touchEndTransform = CATransform3DMakeScale(1.5, 1.5, 1);
        self.userInteractionEnabled = NO;
    }
    return self;
}

#pragma mark - setter

- (void)setBackgroundColor:(UIColor *)color
{
    [super setBackgroundColor:color];
    self.layer.borderColor = [color colorWithAlphaComponent:0.6f].CGColor;
}

- (void)updateWithTouch:(UITouch *)touch
{
    CGPoint point = [touch locationInView:self.superview];
    self.center = point;
    if (@available(iOS 9.0, *)) {
        CGFloat force = MIN(touch.force, touch.maximumPossibleForce) <= 0 ? 0 : touch.force / touch.maximumPossibleForce;
        self.lastScale = CGPointMake(1 + force * CCDefaultForceTouchScale, 1 + force * CCDefaultForceTouchScale);
        self.transform = CGAffineTransformMakeScale(self.lastScale.x, self.lastScale.y);
        UIColor *forceColor = [self interpolatedColorFromStartColor:self.color endColor:UIColor.redColor fraction:force];
        self.backgroundColor = [forceColor colorWithAlphaComponent:0.4];
    }
}

- (UIColor *)interpolatedColorFromStartColor:(UIColor *)startColor endColor:(UIColor *)endColor fraction:(CGFloat)fraction
{
    fraction = MIN(1, MAX(0, fraction));
    if (fraction == 0) return startColor;

    const CGFloat *c1 = CGColorGetComponents(startColor.CGColor);
    const CGFloat *c2 = CGColorGetComponents(endColor.CGColor);

    CGFloat r = c1[ 0 ] + (c2[ 0 ] - c1[ 0 ]) * fraction;
    CGFloat g = c1[ 1 ] + (c2[ 1 ] - c1[ 1 ]) * fraction;
    CGFloat b = c1[ 2 ] + (c2[ 2 ] - c1[ 2 ]) * fraction;

    return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}

- (void)removeFromSuperviewWithAnimation
{
    __weak typeof(self) weakself = self;
    [UIView animateWithDuration:self.touchEndAnimationDuration
                     animations:^{
        weakself.alpha = 0.0f;
        weakself.layer.transform = weakself.touchEndTransform;
    }
                     completion:^(BOOL finished) {
        [weakself removeFromSuperview];
    }];
}

@end
