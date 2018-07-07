//
//  UIViewController+CCHook.m
//  CCDebugTool
//
//  Created by CC on 2017/11/10.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "UIViewController+CCHook.h"
#import <objc/runtime.h>
#import "CCDebugCrashHelper.h"

@implementation UIViewController (CCHook)

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
    AutomaticWritingSwizzleSelector([self class], @selector(viewWillAppear:), @selector(CCDebutTool_viewWillAppear:));
}

- (void)CCDebutTool_viewWillAppear:(BOOL)animated
{
    if (self.navigationController.visibleViewController) {
        NSString *mClassName = [NSString stringWithUTF8String:object_getClassName(self.navigationController.visibleViewController)];
        if (![mClassName hasPrefix:@"CC"]){
            [[CCDebugCrashHelper manager].crashLastStep addObject:[NSString stringWithFormat:@"%@ - viewDidAppear", mClassName]];
        }
    }
    [self CCDebutTool_viewWillAppear:animated];
}

@end
