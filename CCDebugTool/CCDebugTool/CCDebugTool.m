//
//  CCDebugTool.m
//  CCKit
//
// Copyright (c) 2015 CC ( https://github.com/gmaukh4517/CCKit )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "CCDebugTool.h"
#import <objc/runtime.h>

#import "CCNetworkObserver.h"

#import "CCAppFluecyMonitor.h"
#import "CCLogMonitoring.h"
#import "CCMonitorService.h"
#import "CCUncaughtExceptionHandler.h"

#import "FBAllocationTrackerManager.h"
#import "FBAssociationManager.h"

#import "CCDebugLogViewController.h"
#import "CCDebugNetworkViewController.h"
#import "CCMemoryProfilerViewController.h"
#import "CCToolViewController.h"

#import "CCDebugTabbarResources.h"


#pragma mark -
#pragma mark :. 苹果自带debug

/**
 在iOS 11中，Apple添加了额外的检查以禁用此叠加层，除非设备是内部设备。 为了解决这个问题，我们将其淘汰出局
 - [UIDebuggingInformationOverlay init]方法（如果是，则返回nil该设备是非内部的）
 **/
#if defined(DEBUG) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0

@interface UIWindow (PrivateMethods)
- (void)_setWindowControlsStatusBarOrientation:(BOOL)orientation;
@end

@interface _FakeWindowClass : UIWindow
@end

@implementation _FakeWindowClass

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class UIDebuggingInformationOverlayClass = NSClassFromString(@"UIDebuggingInformationOverlay");
        Method originalMethod = class_getInstanceMethod(UIDebuggingInformationOverlayClass, @selector(init));
        Method swizzledMethod = class_getInstanceMethod([_FakeWindowClass class], @selector(initSwizzled));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

- (instancetype)initSwizzled
{
    self = [super init];
    if (self) {
        [self _setWindowControlsStatusBarOrientation:NO];
    }
    return self;
}

@end

#endif


@interface _FakeGestureRecognizer : UIGestureRecognizer
- (UIGestureRecognizerState)state;
@end

@implementation _FakeGestureRecognizer
// [[UIDebuggingInformationOverlayInvokeGestureHandler mainHandler] _handleActivationGesture:(UIGestureRecognizer *)]
// requires a UIGestureRecognizer, as it checks the state of it. We just fake that here.
- (UIGestureRecognizerState)state
{
    return UIGestureRecognizerStateEnded;
}
@end


#pragma mark -
#pragma mark :. CCDebugTool

@interface CCDebugWindow : UIWindow

@end

@implementation CCDebugWindow

- (void)becomeKeyWindow
{
    //    [[[UIApplication sharedApplication].delegate window] makeKeyWindow];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.frame;
    if (@available(iOS 11.0, *)) {
        if ([UIApplication sharedApplication].keyWindow.safeAreaInsets.top == 44)
            frame.origin.y = 30;
    }
    
    self.frame = frame;
}

@end

@interface CCDebugTool ()

@property (nonatomic, strong) UITabBarController *debugTabBar;
@property (nonatomic, strong) CCDebugWindow *debugWindow;

@property (nonatomic, strong) NSTimer *debugTimer;

@end

@implementation CCDebugTool

+ (instancetype)manager
{
    static CCDebugTool *tool;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        tool = [[CCDebugTool alloc] init];
    });
    return tool;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.mainColor = [UIColor colorWithRed:0.223 green:0.698 blue:1 alpha:1.f];
        self.maxCrashCount = 20;
        self.maxLogsCount = 20;
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *_Nonnull note) {
            [self showOnStatusBar];
        }];
    }
    return self;
}

/**
 *  @author CC, 16-03-05
 *
 *  @brief 状态栏显示Debug按钮
 */
- (void)showOnStatusBar
{
    CCDebugWindow *debugWindow = [[CCDebugWindow alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width - 150) / 2, 0, 150, 22)];
    debugWindow.rootViewController = [UIViewController new];
    debugWindow.rootViewController.view.backgroundColor = [UIColor clearColor];
    debugWindow.rootViewController.view.userInteractionEnabled = NO;
    debugWindow.windowLevel = UIWindowLevelStatusBar + 1;
    debugWindow.hidden = NO;
    debugWindow.alpha = 1;
    
    [CCMonitorService start:debugWindow];
    [CCMonitorService mainColor:[UIColor colorWithRed:245 / 255.f green:116 / 255.f blue:91 / 255.f alpha:1.f]];
    
    UIButton *debugButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 150, 22)];
    [debugButton addTarget:self action:@selector(showDebug) forControlEvents:UIControlEventTouchUpInside];
    [debugWindow addSubview:debugButton];
    [debugWindow bringSubviewToFront:debugButton];
    _debugWindow = debugWindow;
    
    //苹果自带debug
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id overlayClass = NSClassFromString(@"UIDebuggingInformationOverlay");
    [overlayClass performSelector:NSSelectorFromString(@"prepareDebuggingOverlay")];
#pragma clang diagnostic pop
}


/**
 *  @author CC, 16-03-05
 *
 *  @brief 启动Debug检测
 */
- (void)enableDebugMode
{
    [CCNetworkObserver setEnabled:YES];
    [[CCLogMonitoring manager] startMonitoring];
    InstalCrashHandler();
    [[CCAppFluecyMonitor sharedMonitor] startMonitoring];
    [self enableProfiler];
}

+ (void)toggleVisibility
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (@available(iOS 11.0, *)) {
        id overlayClass = NSClassFromString(@"UIDebuggingInformationOverlay");
        [overlayClass performSelector:NSSelectorFromString(@"overlay")];
        id handlerClass = NSClassFromString(@"UIDebuggingInformationOverlayInvokeGestureHandler");
        
        id handler = [handlerClass performSelector:NSSelectorFromString(@"mainHandler")];
        [handler performSelector:NSSelectorFromString(@"_handleActivationGesture:") withObject:[[_FakeGestureRecognizer alloc] init]];
    } else {
        id overlayClass = NSClassFromString(@"UIDebuggingInformationOverlay");
        id overlay = [overlayClass performSelector:NSSelectorFromString(@"overlay")];
        [overlay performSelector:NSSelectorFromString(@"toggleVisibility")];
    }
#pragma clang diagnostic pop
}

- (void)setServiceParameters:(NSArray<NSDictionary *> *)parameters
{
    if (parameters) {
        NSMutableDictionary *serviceAddressConifg = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"serviceAddressConifg"]];
        NSMutableArray *address = [NSMutableArray arrayWithArray:[serviceAddressConifg objectForKey:@"address"]];
        
        for (NSDictionary *item in parameters) {
            id object = [address filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id == %@", [item objectForKey:@"id"]]].lastObject;
            if (!object)
                [address addObject:item];
        }
        
        [serviceAddressConifg setObject:address forKey:@"address"];
        [[NSUserDefaults standardUserDefaults] setObject:serviceAddressConifg forKey:@"serviceAddressConifg"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (NSDictionary *)getServiceParameter
{
    NSDictionary *parameter;
    NSMutableDictionary *serviceAddressConifg = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"serviceAddressConifg"]];
    if ([[serviceAddressConifg objectForKey:@"conifg"] boolValue]) {
        parameter = [[[serviceAddressConifg objectForKey:@"address"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"selected = YES"]].lastObject objectForKey:@"parameter"];
    }
    return parameter;
}

- (NSArray *)CatonLogger
{
    return [CCAppFluecyMonitor obtainFluencyLogs];
}

- (NSArray *)CrashLogger
{
    return [CCUncaughtExceptionHandler obtainCrashLogs];
}

+ (UIImage *)tabbarImage:(NSString *)fileName
{
    return [CCDebugTool cc_bundle:fileName inDirectory:@"tabbar"];
}

+ (UIImage *)cc_bundle:(NSString *)fileName
{
    return [CCDebugTool cc_bundle:fileName inDirectory:nil];
}

+ (UIImage *)cc_bundle:(NSString *)fileName
           inDirectory:(NSString *)inDirectory
{
    NSBundle *imageBundle = [CCDebugTool cc_debugBundle];
    NSString *imagePath = [[imageBundle resourcePath] stringByAppendingPathComponent:fileName];
    if (inDirectory)
        imagePath = [[[imageBundle resourcePath] stringByAppendingPathComponent:inDirectory] stringByAppendingPathComponent:fileName];
    
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    if (!image)
        image = [UIImage imageNamed:fileName];
    
    return image;
}

+ (NSBundle *)cc_debugBundle
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"CCDebugTool" ofType:@"bundle"];
    if (!path) {
        path = [[NSBundle mainBundle] pathForResource:@"CCDebugTool" ofType:@"bundle" inDirectory:@"CCDebugTool.framework/"];
    }
    return [NSBundle bundleWithPath:path];
}

#pragma mark -
#pragma mark :. UI

- (void)enableProfiler
{
    [FBAssociationManager hook];
    [[FBAllocationTrackerManager sharedManager] startTrackingAllocations];
    [[FBAllocationTrackerManager sharedManager] enableGenerations];
}

- (void)showDebug
{
    if (!self.debugTabBar) {
        self.debugTabBar = [[UITabBarController alloc] init];
        self.debugTabBar.tabBar.tintColor = self.mainColor;
        self.debugTabBar.tabBar.unselectedItemTintColor = [UIColor blackColor];
        self.debugTabBar.tabBar.translucent = NO;
        
        [self initializationNav:[CCDebugNetworkViewController new] title:@"HTTP" imageNamed:[CCDebugTabbarResources networkNOIcon] selectedImage:[CCDebugTabbarResources networkYESIcon]];
        [self initializationNav:[CCDebugLogViewController new] title:@"LOG" imageNamed:[CCDebugTabbarResources logNOIcon] selectedImage:[CCDebugTabbarResources logYESIcon]];
        [self initializationNav:[CCMemoryProfilerViewController new] title:@"Cycle" imageNamed:[CCDebugTabbarResources cycleNOIcon] selectedImage:[CCDebugTabbarResources cycleYESIcon]];
        [self initializationNav:[CCToolViewController new] title:@"TOOL" imageNamed:[CCDebugTabbarResources toolNOIcon] selectedImage:[CCDebugTabbarResources toolYESIcon]];
        //        UINavigationController *debugMonitorNav = [self initializationNav:[CCMonitorViewController new] tabBarItemName:@"Monitor"];
    }
    
    if (self.debugTabBar.isViewLoaded && self.debugTabBar.view.window) {
        [self.debugTabBar dismissViewControllerAnimated:YES completion:nil];
    } else {
        UIViewController *rootViewController = [[[UIApplication sharedApplication].windows firstObject] rootViewController];
        UIViewController *presentedViewController = rootViewController.presentedViewController;
        self.debugTabBar.modalPresentationStyle = UIModalPresentationFullScreen;
        [presentedViewController ?: rootViewController presentViewController:self.debugTabBar animated:YES completion:nil];
    }
}

- (void)initializationNav:(UIViewController *)viewController title:(NSString *)title imageNamed:(UIImage *)imageNamed selectedImage:(UIImage *)selectedImage
{
    UINavigationController *debugNav = [[UINavigationController alloc] initWithRootViewController:viewController];
    debugNav.navigationItem.title = title;
    debugNav.tabBarItem.title = title;
    debugNav.tabBarItem.image = [imageNamed imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    debugNav.tabBarItem.selectedImage = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [debugNav.navigationBar setBarTintColor:self.mainColor];
    [debugNav.navigationBar setTintColor:[UIColor whiteColor]];
    NSMutableDictionary *Attributes = [NSMutableDictionary dictionaryWithDictionary:[UINavigationBar appearance].titleTextAttributes];
    [Attributes setObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    [debugNav.navigationBar setTitleTextAttributes:Attributes];
    
    [self.debugTabBar addChildViewController:debugNav];
}

@end
