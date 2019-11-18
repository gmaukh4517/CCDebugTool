//
//  UINavigationController+CCHook.m
//  CCDebugTool
//
//  Created by CC on 2017/11/10.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCDebugCrashHelper.h"
#import "UINavigationController+CCHook.h"
#import <objc/runtime.h>

@implementation UINavigationController (CCHook)

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
    AutomaticWritingSwizzleSelector([self class], @selector(pushViewController:animated:), @selector(CCDebutTool_pushViewController:animated:));
    AutomaticWritingSwizzleSelector([self class], @selector(popViewControllerAnimated:), @selector(CCDebutTool_popViewControllerAnimated:));
}

- (void)CCDebutTool_pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NSString *mClassName = [NSString stringWithUTF8String:object_getClassName(viewController)];
    if (![mClassName hasPrefix:@"CC"]) {
        NSString *pushInfo = [NSString stringWithFormat:@" %@ - (push) > %@", [NSString stringWithUTF8String:object_getClassName(self.topViewController)], mClassName];
        [[CCDebugCrashHelper manager].crashLastStep addObject:pushInfo];
    }

    [self CCDebutTool_pushViewController:viewController animated:animated];
}

- (void)CCDebutTool_popViewControllerAnimated:(BOOL)animated
{
    NSString *mClassName = [NSString stringWithUTF8String:object_getClassName(self.topViewController)];
    [self CCDebutTool_popViewControllerAnimated:animated];
    if (![mClassName hasPrefix:@"CC"]) {
        NSString *previousClassName = [NSString stringWithUTF8String:object_getClassName(self.viewControllers.lastObject)];
        NSString *popInfo = [NSString stringWithFormat:@" %@ - (pop) > %@", mClassName, previousClassName];
        [[CCDebugCrashHelper manager].crashLastStep addObject:popInfo];
    }
}

@end
