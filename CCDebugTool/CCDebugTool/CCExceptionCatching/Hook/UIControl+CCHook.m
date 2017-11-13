//
//  UIControl+CCHook.m
//  CCDebugTool
//
//  Created by CC on 2017/11/10.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "UIControl+CCHook.h"
#import <objc/runtime.h>
#import "CCDebugCrashHelper.h"

@implementation UIControl (CCHook)

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

+ (void)CCHook
{
    AutomaticWritingSwizzleSelector([self class], @selector(sendAction:to:forEvent:), @selector(cc_sendAction:to:forEvent:));
}

- (void)cc_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event
{
    [self cc_sendAction:action to:target forEvent:event];
    
    NSString *actionDetailInfo = [NSString stringWithFormat:@" %@ - %@ - %@", NSStringFromClass([target class]), NSStringFromClass([self class]), NSStringFromSelector(action)];
    NSLog(@"%@",actionDetailInfo);
}

@end
