//
//  UIControl+CCHook.m
//  CCDebugTool
//
//  Created by CC on 2017/11/10.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCDebugCrashHelper.h"
#import "UIControl+CCHook.h"
#import <objc/runtime.h>

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
        NSString *controlName = NSStringFromClass([self class]);
        if ([self isKindOfClass:[UIButton class]]) {
            UIButton *senderButton = (UIButton *)self;
            if (senderButton.currentTitle)
                controlName = [NSString stringWithFormat:@"%@(%@)", controlName, senderButton.currentTitle];
        } else if ([self isKindOfClass:[UIBarButtonItem class]]) {
            UIBarButtonItem *senderButton = (UIBarButtonItem *)self;
            if (senderButton.title)
                controlName = [NSString stringWithFormat:@"%@(%@)", controlName, senderButton.title];
            else if ([senderButton.customView isKindOfClass:[UIButton class]]) {
                UIButton *senderCystinViewButton = (UIButton *)senderButton.customView;
                if (senderCystinViewButton.currentTitle)
                    controlName = [NSString stringWithFormat:@"%@(%@)", controlName, senderCystinViewButton.currentTitle];
            }
        }

        NSString *actionDetailInfo = [NSString stringWithFormat:@" %@ -> %@ -> %@", mClassName, controlName, NSStringFromSelector(action)];
        [[CCDebugCrashHelper manager].crashLastStep addObject:actionDetailInfo];
    }
    [self CCDebutTool_sendAction:action to:target forEvent:event];
}

@end
