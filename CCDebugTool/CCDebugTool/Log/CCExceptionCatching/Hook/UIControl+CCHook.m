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
    AutomaticWritingSwizzleSelector([self class], @selector(sendAction:to:forEvent:), @selector(CCDebutTool_sendAction:to:forEvent:));
}

- (void)CCDebutTool_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event
{
    NSString *mClassName = NSStringFromClass([target class]);
    if (![mClassName hasPrefix:@"CC"]) {
        NSString *actionDetailInfo = [NSString stringWithFormat:@" %@ -> %@ -> %@", mClassName, NSStringFromClass([self class]), NSStringFromSelector(action)];
        [[CCDebugCrashHelper manager].crashLastStep addObject:actionDetailInfo];
    }
    [self CCDebutTool_sendAction:action to:target forEvent:event];
}

@end
