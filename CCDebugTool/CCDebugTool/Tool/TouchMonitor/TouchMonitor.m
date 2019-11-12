//
//  TouchMonitor.m
//  CCDebugTool
//
//  Created by CC on 2019/11/11.
//  Copyright © 2019 CC. All rights reserved.
//

#import "TouchMonitor.h"
#import "CCTouchWindow.h"
#import <objc/runtime.h>

static inline void AutomaticWritingSwizzleSelector(Class class, SEL originalSelector, SEL swizzledSelector)
{
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    if (class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

static BOOL _showTouch = NO;
static CCTouchWindow *_touchWindow = nil;

@implementation TouchMonitor

+ (BOOL)touchSwitch
{
    return _showTouch;
}

+ (void)setPluginSwitch:(BOOL)pluginSwitch
{
    _showTouch = pluginSwitch;
    if (pluginSwitch) {
        if (!_touchWindow) {
            _touchWindow = [[CCTouchWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }
        _touchWindow.hidden = NO;
    } else {
        [_touchWindow destroy];
        _touchWindow = nil;
    }
}


+ (void)handleToucheEvent:(UIEvent *)event
{
    [_touchWindow displayEvent:event];
}

@end


#pragma mark -
#pragma mark :. UIApplication

@interface UIApplication (TouchMonitor)

@end

@implementation UIApplication (TouchMonitor)

+ (void)load
{
    AutomaticWritingSwizzleSelector([self class], @selector(sendEvent:), @selector(hook_sendEvent:));
}

- (void)hook_sendEvent:(UIEvent *)event
{
    if (_showTouch && event.type == UIEventTypeTouches)
        [TouchMonitor handleToucheEvent:event];
    [self hook_sendEvent:event];
}

@end
