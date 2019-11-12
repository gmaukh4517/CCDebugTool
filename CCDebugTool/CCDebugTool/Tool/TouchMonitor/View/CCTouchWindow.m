//
//  CCTouchWindow.m
//  CCDebugTool
//
//  Created by CC on 2019/11/11.
//  Copyright © 2019 CC. All rights reserved.
//

#import "CCTouchWindow.h"
#import "CCTouchFingerView.h"
#import <objc/runtime.h>

static const void *kCCFingerViewAssociatedKey = &kCCFingerViewAssociatedKey;

@interface CCTouchWindow ()

@property (nonatomic, weak) UIView *touchesView;

@end

@implementation CCTouchWindow

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        // 防止旋转时四周有黑边
        self.clipsToBounds = YES;
        // 暂时关闭暗黑模式
        if (@available(iOS 13.0, *))
            self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;

        self.windowLevel = CGFLOAT_MAX;
        self.userInteractionEnabled = NO;
        self.rootViewController = [UIViewController new];
        self.rootViewController.view.userInteractionEnabled = NO;
        self.touchesView = self.rootViewController.view;
    }
    return self;
}

- (void)destroy
{
    self.hidden = YES;
    if (self.rootViewController.presentedViewController) {
        [self.rootViewController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    self.rootViewController = nil;
}


#pragma mark - event

- (void)displayEvent:(UIEvent *)event
{
    NSSet *touches = [event allTouches];
    for (UITouch *touch in touches) {
        if (touch.phase == UITouchPhaseCancelled || touch.phase == UITouchPhaseEnded)
            [self removeFingerViewForTouch:touch];
        else
            [self updateFingerViewForTouch:touch];
    }
}

- (void)updateFingerViewForTouch:(UITouch *)touch
{
    CCTouchFingerView *fingerView = objc_getAssociatedObject(touch, kCCFingerViewAssociatedKey);
    CGPoint point = [touch locationInView:self.touchesView];
    if (!fingerView) {
        fingerView = [[CCTouchFingerView alloc] initWithPoint:point];
        objc_setAssociatedObject(touch, kCCFingerViewAssociatedKey, fingerView, OBJC_ASSOCIATION_ASSIGN);
        [self.touchesView addSubview:fingerView];
    }
    [fingerView updateWithTouch:touch];
}

- (void)removeFingerViewForTouch:(UITouch *)touch
{
    CCTouchFingerView *fingerView = objc_getAssociatedObject(touch, kCCFingerViewAssociatedKey);
    if (fingerView) {
        objc_setAssociatedObject(touch, kCCFingerViewAssociatedKey, nil, OBJC_ASSOCIATION_ASSIGN);
        [fingerView removeFromSuperviewWithAnimation];
    }
}

@end
