//
//  UINavigationController+CCHook.m
//  CCDebugTool
//
//  Created by CC on 2017/11/10.
//  Copyright © 2017年 CC. All rights reserved.
//

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

+(void)CCHook
{
    AutomaticWritingSwizzleSelector([self class], @selector(pushViewController:animated:), @selector(CCDebutTool_pushViewController:animated:));
    AutomaticWritingSwizzleSelector([self class], @selector(popViewControllerAnimated:), @selector(CCDebutTool_popViewControllerAnimated:));
}

- (void)CCDebutTool_pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self CCDebutTool_pushViewController:viewController animated:animated];
}

-(void)CCDebutTool_popViewControllerAnimated:(BOOL)animated
{
    [self CCDebutTool_popViewControllerAnimated:animated];
}

@end
