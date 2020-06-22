//
//  CCHook.m
//  CCDebugTool
//
//  Created by CC on 2019/11/18.
//  Copyright © 2019 CC. All rights reserved.
//

#import "CCHook.h"
#import "CCDebugCrashHelper.h"
#import "CCOperateMonitor.h"
#import "CCStatistics.h"
#import <WebKit/WebKit.h>
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

void ccdebug_AutomaticWritingExchangeSelector(Class originalClass, SEL originalSelector, Class replacedClass, SEL swizzledSelector)
{
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method replacedMethod = class_getInstanceMethod(replacedClass, swizzledSelector);
    if (class_addMethod(originalClass, swizzledSelector, method_getImplementation(replacedMethod), method_getTypeEncoding(replacedMethod))) {
        Method newMethod = class_getInstanceMethod(originalClass, swizzledSelector);
        method_exchangeImplementations(originalMethod, newMethod);
    } else {
        NSLog(@"Already hook class --> (%@)", NSStringFromClass(originalClass));
    }
}

#pragma mark -
#pragma mark :. UINavigationController

@implementation UINavigationController (CCHook)

+ (void)CCHook
{
    AutomaticWritingSwizzleSelector([self class], @selector(pushViewController:animated:), @selector(CCDebugTool_pushViewController:animated:));
    //    AutomaticWritingSwizzleSelector([self class], @selector(popViewControllerAnimated:), @selector(CCDebugTool_popViewControllerAnimated:)); // 真机闪退 模拟器偶尔闪退 EXC_BAD_ACCESS
}

- (void)CCDebugTool_pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NSString *mClassName = [NSString stringWithUTF8String:object_getClassName(viewController)];
    if (![mClassName hasPrefix:@"CC"]) {
        NSString *pushInfo = [NSString stringWithFormat:@" %@ - (push) > %@", [NSString stringWithUTF8String:object_getClassName(self.topViewController)], mClassName];
        [[CCDebugCrashHelper manager].crashLastStep addObject:pushInfo];
        [[CCOperateMonitor manager] appOperateLogWrite:pushInfo];
    }
    
    [self CCDebugTool_pushViewController:viewController animated:animated];
}

- (void)CCDebugTool_popViewControllerAnimated:(BOOL)animated
{
    NSString *mClassName = [NSString stringWithUTF8String:object_getClassName(self.topViewController)];
    if (![mClassName hasPrefix:@"CC"]) {
        NSString *previousClassName = [NSString stringWithUTF8String:object_getClassName(self.viewControllers.lastObject)];
        NSString *popInfo = [NSString stringWithFormat:@" %@ - (pop) > %@", mClassName, previousClassName];
        [[CCDebugCrashHelper manager].crashLastStep addObject:popInfo];
        [[CCOperateMonitor manager] appOperateLogWrite:popInfo];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self CCDebugTool_popViewControllerAnimated:animated];
    });
}

@end

#pragma mark -
#pragma mark :. UIViewController

@implementation UIViewController (CCHook)

+ (void)CCHook
{
    AutomaticWritingSwizzleSelector([self class], @selector(viewDidLoad), @selector(CCDebugTool_viewDidLoad));
    AutomaticWritingSwizzleSelector([self class], @selector(viewWillAppear:), @selector(CCDebugTool_viewWillAppear:));
    AutomaticWritingSwizzleSelector([self class], @selector(viewDidAppear:), @selector(CCDebugTool_viewDidAppear:));
    AutomaticWritingSwizzleSelector([self class], NSSelectorFromString(@"dealloc"), @selector(CCDebugTool_dealloc));
}

- (void)CCDebugTool_viewDidLoad
{
    NSString *mClassName = NSStringFromClass(self.class);
    if (![mClassName hasPrefix:@"CC"] && ![mClassName hasPrefix:@"UI"])
        [[CCStatistics manager] viewControllerEnter:mClassName];
    
    [self CCDebugTool_viewDidLoad];
}

- (void)CCDebugTool_viewWillAppear:(BOOL)animated
{
    if (self.navigationController.visibleViewController) {
        NSString *mClassName = [NSString stringWithUTF8String:object_getClassName(self.navigationController.visibleViewController)];
        if (![mClassName hasPrefix:@"CC"]) {
            NSString *viewWillAppearInfo = [NSString stringWithFormat:@"%@ - viewWillAppear", mClassName];
            [[CCDebugCrashHelper manager].crashLastStep addObject:viewWillAppearInfo];
            [[CCOperateMonitor manager] appOperateLogWrite:viewWillAppearInfo];
        }
    }
    [self CCDebugTool_viewWillAppear:animated];
}


- (void)CCDebugTool_viewDidAppear:(BOOL)animated
{
    NSString *mClassName = NSStringFromClass(self.class);
    if (![mClassName hasPrefix:@"CC"] && ![mClassName hasPrefix:@"UI"])
        [[CCStatistics manager] viewControllerAppear:mClassName];
    [self CCDebugTool_viewDidAppear:animated];
}

- (void)CCDebugTool_dealloc
{
    NSString *mClassName = NSStringFromClass(self.class);
    if (![mClassName hasPrefix:@"CC"] && ![mClassName hasPrefix:@"UI"])
        [[CCStatistics manager] viewControllerExit:mClassName];
    [self CCDebugTool_dealloc];
}

@end

#pragma mark -
#pragma mark :. UIControl

@implementation UIControl (CCHook)

+ (void)CCHook
{
    AutomaticWritingSwizzleSelector([self class], @selector(sendAction:to:forEvent:), @selector(CCDebugTool_sendAction:to:forEvent:));
}

- (void)CCDebugTool_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event
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
        [[CCOperateMonitor manager] appOperateLogWrite:actionDetailInfo];
    }
    [self CCDebugTool_sendAction:action to:target forEvent:event];
}

@end

#pragma mark -
#pragma mark :. UITableView

@implementation UITableView (CCHook)

+ (void)load
{
    [super load];
    AutomaticWritingSwizzleSelector([self class], @selector(setDelegate:), @selector(CCDebugTool_setDelegate:));
}

- (void)CCDebugTool_setDelegate:(id<UITableViewDelegate>)delegate
{
    [self CCDDebugTool_exchangeUIApplicationDelegateMethod:delegate];
    [self CCDebugTool_setDelegate:delegate];
}


- (void)CCDDebugTool_exchangeUIApplicationDelegateMethod:(id)delegate
{
    ccdebug_AutomaticWritingExchangeSelector([delegate class], @selector(tableView:didSelectRowAtIndexPath:), [self class], @selector(CCDebugTool_tableView:didSelectRowAtIndexPath:));
}

- (void)CCDebugTool_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *mClassName = NSStringFromClass([[tableView delegate] class]);
    if (![mClassName hasPrefix:@"CC"]) {
        NSString *actionDetailInfo = [NSString stringWithFormat:@" %@ -> %@ -> tableView:didSelectRowAtIndexPath:", mClassName, NSStringFromClass([tableView class])];
        [[CCDebugCrashHelper manager].crashLastStep addObject:actionDetailInfo];
        [[CCOperateMonitor manager] appOperateLogWrite:actionDetailInfo];
    }
    [self CCDebugTool_tableView:tableView didSelectRowAtIndexPath:indexPath];
}

@end

#pragma mark -
#pragma mark :. UICollectionView

@implementation UICollectionView (CCHook)

+ (void)load
{
    [super load];
    AutomaticWritingSwizzleSelector([self class], @selector(setDelegate:), @selector(CCDebugTool_setDelegate:));
}

- (void)CCDebugTool_setDelegate:(id<UICollectionViewDelegate>)delegate
{
    [self CCDDebugTool_exchangeUIApplicationDelegateMethod:delegate];
    [self CCDebugTool_setDelegate:delegate];
}


- (void)CCDDebugTool_exchangeUIApplicationDelegateMethod:(id)delegate
{
    ccdebug_AutomaticWritingExchangeSelector([delegate class], @selector(collectionView:didSelectItemAtIndexPath:), [self class], @selector(CCDebugTool_collectionView:didSelectItemAtIndexPath:));
}

- (void)CCDebugTool_collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    NSString *mClassName = NSStringFromClass([[collectionView delegate] class]);
    if (![mClassName hasPrefix:@"CC"]) {
        NSString *actionDetailInfo = [NSString stringWithFormat:@" %@ -> %@ -> collectionView:didSelectItemAtIndexPath:", mClassName, NSStringFromClass([collectionView class])];
        [[CCDebugCrashHelper manager].crashLastStep addObject:actionDetailInfo];
        [[CCOperateMonitor manager] appOperateLogWrite:actionDetailInfo];
    }
    [self CCDebugTool_collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

@end

#pragma mark -
#pragma mark :. WekWebView

#define HookKeys @[   \
@"onbeforeunload" \
]

@interface CCHookHandler : NSObject <WKScriptMessageHandler>

@end

@implementation CCHookHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSData *jsonData = [message.body dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    
    NSString *mClassName = [jsonDic objectForKey:@"url"];
    NSURL *url = [NSURL URLWithString:mClassName];
    NSString *addressName = url.host;
    if (url.scheme && url.host)
        addressName = [NSString stringWithFormat:@"%@://%@", url.scheme, url.host];
    
    if ([message.name isEqualToString:@"enter"]) {
        [CCOperateMonitor manager].webCurrentURL = mClassName;
        [[CCStatistics manager] viewControllerEnter:mClassName];
        [[CCOperateMonitor manager] webOperateLogWrite:[NSString stringWithFormat:@"%@\n\n%@ - loaded", [self URLDecodedString:mClassName], addressName]];
    } else if ([message.name isEqualToString:@"onload"]) {
        [CCOperateMonitor manager].webCurrentURL = mClassName;
        [[CCStatistics manager] viewControllerAppear:mClassName];
        [[CCOperateMonitor manager] webOperateLogWrite:[NSString stringWithFormat:@"%@\n\n%@ - onload", [self URLDecodedString:mClassName], addressName]];
    } else if ([message.name isEqualToString:@"hashURL"]) {
        NSString *hashType = [jsonDic objectForKey:@"hashType"];
        NSString *oldURL = [jsonDic objectForKey:@"oldURL"];
        NSString *operateLog;
        if ([hashType isEqualToString:@"push"]) {
            operateLog = [NSString stringWithFormat:@"%@\n\n> push >\n\n %@", [self URLDecodedString:oldURL], [self URLDecodedString:mClassName]];
        } else if ([hashType isEqualToString:@"pop"]) {
            [[CCStatistics manager] viewControllerExit:oldURL];
            operateLog = [NSString stringWithFormat:@"%@\n\n> pop >\n\n %@", [self URLDecodedString:oldURL], [self URLDecodedString:mClassName]];
        }
        [[CCOperateMonitor manager] webOperateLogWrite:operateLog];
    } else if ([message.name isEqualToString:@"onbeforeunload"]) {
        [[CCStatistics manager] viewControllerExit:mClassName];
        [[CCOperateMonitor manager] webOperateLogWrite:[NSString stringWithFormat:@"%@\n\n%@ - onbeforeunload", [self URLDecodedString:mClassName], addressName]];
    } else if ([message.name isEqualToString:@"clickEvent"]) {
        NSString *actionDetailInfo = [NSString stringWithFormat:@"%@\n\n%@ -> %@ -> %@", [self URLDecodedString:mClassName], addressName, [jsonDic objectForKey:@"controlName"], [jsonDic objectForKey:@"action"]];
        [[CCOperateMonitor manager] webOperateLogWrite:actionDetailInfo];
    } else if ([message.name isEqualToString:@"haha"]) {
        NSLog(@"111111111 %@", jsonDic);
    }
}

- (NSString *)URLDecodedString:(NSString *)urlString
{
    NSString *result = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                                             (__bridge CFStringRef)urlString,
                                                                                                             CFSTR(""),
                                                                                                             CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    return [[result stringByRemovingPercentEncoding] stringByRemovingPercentEncoding];
}

@end

@implementation WKUserContentController (CCHook)


+ (void)load
{
    AutomaticWritingSwizzleSelector([self class], @selector(init), @selector(CCHook_init));
    AutomaticWritingSwizzleSelector([self class], NSSelectorFromString(@"dealloc"), @selector(CCHook_dealloc));
}

- (instancetype)CCHook_init
{
    WKUserContentController *wKUserContentController = [self CCHook_init];
    [wKUserContentController CCHook_install];
    return wKUserContentController;
}

- (void)CCHook_dealloc
{
    if ([CCOperateMonitor manager].webCurrentURL)
        [[CCStatistics manager] viewControllerExit:[CCOperateMonitor manager].webCurrentURL];
    [[CCOperateMonitor manager] webOperateEnd];
    [self cc_uninstallHookLog];
}

static const void *CCHookLogKey = &CCHookLogKey;
- (void)cc_uninstallHookLog
{
    for (NSString *key in HookKeys) {
        [self removeScriptMessageHandlerForName:key];
    }
    objc_setAssociatedObject(self, CCHookLogKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)CCHook_install
{
    if ([objc_getAssociatedObject(self, CCHookLogKey) boolValue])
        return;
    
    objc_setAssociatedObject(self, CCHookLogKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    CCHookHandler *handler = [CCHookHandler new];
    [self CCHookJS:handler];
}

- (void)CCHookJS:(CCHookHandler *)handler
{
    //页面URL变化跳转
    NSString *hashJS = @"var isForward = false; var currentURL = '';\
    window.onhashchange = function(hash) {\
    var newURL = event.newURL.slice(-2, -1) == '#' ? event.newURL.slice(-1) : 0;\
    var oldURL = event.oldURL.slice(-2, -1) == '#' ? event.oldURL.slice(-1) : 0;\
    const params = { 'url': window.location.href,'obj':currentURL,'newURL':hash.newURL, 'oldURL': hash.oldURL };\
    if (!isForward) {\
    if (parseInt(newURL) < parseInt(oldURL)) {\
    console.log('单页面中业务后退逻辑');\
    } else {\
    isForward = true;\
    params['hashType']='push';\
    }\
    } else {\
    isForward = false;\
    params['hashType']='pop';\
    }\
    window.webkit.messageHandlers.hashURL.postMessage(JSON.stringify(params));\
    };";
    [self initHookJS:handler hookKey:@"hashURL" hookJS:hashJS];
    
    //页面加载
    NSString *enterJS = @"document.addEventListener('DOMContentLoaded',() =>{\
    const params = {'url':window.location.href};\
    window.webkit.messageHandlers.enter.postMessage(JSON.stringify(params));\
    });";
    [self initHookJS:handler hookKey:@"enter" hookJS:enterJS];
    
    //页面加载完成
    NSString *onloadJS = @"document.addEventListener('readystatechange', (event) => {\
    if (document.readyState == 'complete') {\
    currentURL = window.location.href;\
    const params = {'url':window.location.href,'readyState':document.readyState};\
    window.webkit.messageHandlers.onload.postMessage(JSON.stringify(params));\
    }});";
    [self initHookJS:handler hookKey:@"onload" hookJS:onloadJS];
    
    
    NSString *hookJS = @"window.{0} = (function(method) {\
    return function(e) {\
    const params = {'url':window.location.href};\
    window.webkit.messageHandlers.{0}.postMessage(JSON.stringify(params));\
    if (method) {\
    method.call(window, e);\
    }\
    }\
    })(window.{0});";
    
    for (NSString *key in HookKeys)
        [self initHookJS:handler hookKey:key hookJS:[hookJS stringByReplacingOccurrencesOfString:@"{0}" withString:key]];
    
    //页面点击事件
    NSString *clickJS = @"document.onclick = onClick;\
    function onClick(ev) {\
    ev = ev || window.event;\
    var target = ev.target || ev.srcElement;\
    if (target.onclick || target.localName == 'button' || target.localName == 'input' || target.localName == 'a') {\
    const params = { 'url': window.location.href, 'controlName': target.localName };\
    if (target.localName == 'button') {\
    params['action'] = target.innerText;\
    if (target.attributes.onclick) {\
    params['action'] = target.attributes.onclick.textContent;\
    }\
    } else if (target.localName == 'input') {\
    params['action'] = target.type + ' : ' + target.checked;\
    } else if (target.localName == 'a') {\
    params['action'] = target.innerText + ' \n ' + target.href;\
    }\
    window.webkit.messageHandlers.clickEvent.postMessage(JSON.stringify(params));\
    if (target.onclick) {\
    target.onclick();\
    }\
    }\
    }";
    [self initHookJS:handler hookKey:@"clickEvent" hookJS:clickJS];
}

- (void)initHookJS:(CCHookHandler *)handler hookKey:(NSString *)hookKey hookJS:(NSString *)hookJS
{
    [self removeScriptMessageHandlerForName:hookKey];
    [self addScriptMessageHandler:handler name:hookKey];
    [self addUserScript:[[WKUserScript alloc] initWithSource:hookJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO]];
}

@end

#pragma mark -
#pragma mark :. CCHook

@implementation CCHook

+ (void)hookEvent
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UINavigationController CCHook];
        [UIViewController CCHook];
        [UIControl CCHook];
    });
    ccdebug_AutomaticWritingExchangeSelector(NSClassFromString(@"UIGestureRecognizerTarget"), NSSelectorFromString(@"_sendActionWithGestureRecognizer:"), self, @selector(CCDebugTool_sendActionWithGestureRecognizer:));
}

- (void)CCDebugTool_sendActionWithGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    id targetActionPairs = object_getIvar(gestureRecognizer, class_getInstanceVariable([gestureRecognizer class], "_targets"));
    Class targetActionPairClass = NSClassFromString(@"UIGestureRecognizerTarget");
    Ivar targetIvar = class_getInstanceVariable(targetActionPairClass, "_target");
    
    Ivar actionIvar = class_getInstanceVariable(targetActionPairClass, "_action");
    for (id targetActionPair in targetActionPairs) {
        id target = object_getIvar(targetActionPair, targetIvar);
        SEL action = (__bridge void *)object_getIvar(targetActionPair, actionIvar);
        NSString *mClassName = NSStringFromClass([target class]);
        if (![mClassName hasPrefix:@"CC"]) {
            NSString *stateStr = @"UIGestureRecognizerStateRecognized";
            switch (gestureRecognizer.state) {
                case UIGestureRecognizerStatePossible:
                    stateStr = @"UIGestureRecognizerStatePossible";
                    break;
                case UIGestureRecognizerStateBegan:
                    stateStr = @"UIGestureRecognizerStateBegan";
                    break;
                case UIGestureRecognizerStateChanged:
                    stateStr = @"UIGestureRecognizerStateChanged";
                    break;
                case UIGestureRecognizerStateEnded:
                    stateStr = @"UIGestureRecognizerStateEnded";
                    break;
                case UIGestureRecognizerStateCancelled:
                    stateStr = @"UIGestureRecognizerStateCancelled";
                    break;
                case UIGestureRecognizerStateFailed:
                    stateStr = @"UIGestureRecognizerStateFailed";
                    break;
                default:
                    break;
            }
            
            NSString *actionDetailInfo = [NSString stringWithFormat:@" %@ -> %@ -> %@ -> %@ -> %@", mClassName, NSStringFromClass([gestureRecognizer.view class]), NSStringFromClass([gestureRecognizer class]), stateStr, NSStringFromSelector(action)];
            [[CCDebugCrashHelper manager].crashLastStep addObject:actionDetailInfo];
            [[CCOperateMonitor manager] appOperateLogWrite:actionDetailInfo];
        }
    }
    
    [self CCDebugTool_sendActionWithGestureRecognizer:gestureRecognizer];
}

@end
