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
#import "CCNetworkObserver.h"

#import "CCAppFluecyMonitor.h"
#import "CCMonitorService.h"
#import "CCUncaughtExceptionHandler.h"

#import "FBAllocationTrackerManager.h"
#import "FBAssociationManager.h"

#import "CCDebugHttpViewController.h"
#import "CCDebugLogViewController.h"
#import "CCMemoryProfilerViewController.h"
#import "ToolViewController.h"

@interface CCDebugWindow : UIWindow

@end

@implementation CCDebugWindow

- (void)becomeKeyWindow
{
    [[[UIApplication sharedApplication].delegate window] makeKeyWindow];
}

@end


@interface CCDebugTool ()

@property (nonatomic, weak) UITabBarController *debugTabBar;
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
        self.mainColor = [UIColor colorWithRed:28 / 255.f green:134 / 255.f blue:238 / 255.f alpha:1.f];
        self.maxCrashCount = 20;
        self.maxLogsCount = 50;
        self.debugWindow = [[CCDebugWindow alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
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
    self.debugWindow.windowLevel = UIWindowLevelStatusBar + 1;
    self.debugWindow.hidden = NO;
    
    [CCMonitorService start:self.debugWindow];
    [CCMonitorService mainColor:[UIColor colorWithRed:245 / 255.f green:116 / 255.f blue:91 / 255.f alpha:1.f]];
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    UIButton *debugButton = [[UIButton alloc] initWithFrame:CGRectMake((width - 150) / 2, 0, 150, 22)];
    [debugButton addTarget:self action:@selector(showDebug) forControlEvents:UIControlEventTouchUpInside];
    [self.debugWindow addSubview:debugButton];
    [self.debugWindow bringSubviewToFront:debugButton];
}


/**
 *  @author CC, 16-03-05
 *
 *  @brief 启动Debug检测
 */
- (void)enableDebugMode
{
#if DEBUG
    [CCNetworkObserver setEnabled:YES];
//    [NSURLProtocol registerClass:[CCDebugHttpProtocol class]];
    InstalCrashHandler();
    [[CCAppFluecyMonitor sharedMonitor] startMonitoring];
    [self enableProfiler];
    
    __weak typeof(self) wSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [wSelf showOnStatusBar];
    });
#endif
}

- (void)enableProfiler
{
    [FBAssociationManager hook];
    [[FBAllocationTrackerManager sharedManager] startTrackingAllocations];
    [[FBAllocationTrackerManager sharedManager] enableGenerations];
}

- (void)showDebug
{
    if (!self.debugTabBar) {
        UITabBarController *debugTabBar = [[UITabBarController alloc] init];
        
        UINavigationController *debugHTTPNav = [self initializationNav:[CCDebugHttpViewController new] tabBarItemName:@"HTTP"];
        UINavigationController *debugLOGNav = [self initializationNav:[CCDebugLogViewController new]  tabBarItemName:@"LOG"];
        UINavigationController *debugProfilerNav = [self initializationNav:[CCMemoryProfilerViewController new]  tabBarItemName:@"Cycle"];
        UINavigationController *debugSandBoxNav = [self initializationNav:[ToolViewController new]  tabBarItemName:@"TOOL"];
        //        UINavigationController *debugMonitorNav = [self initializationNav:[CCMonitorViewController new] tabBarItemName:@"Monitor"];
        
        debugTabBar.viewControllers = [NSArray arrayWithObjects:debugHTTPNav, debugLOGNav, debugProfilerNav,debugSandBoxNav, nil];
        self.debugTabBar = debugTabBar;
        
        UIViewController *rootViewController = [[[UIApplication sharedApplication].windows firstObject] rootViewController];
        UIViewController *presentedViewController = rootViewController.presentedViewController;
        [presentedViewController ?: rootViewController presentViewController:self.debugTabBar animated:YES completion:nil];
    } else {
        [self.debugTabBar dismissViewControllerAnimated:YES completion:nil];
        self.debugTabBar = nil;
    }
}

- (UINavigationController *)initializationNav:(UIViewController *)viewController tabBarItemName:(NSString *)tabBarItemName
{
    UINavigationController *debugNav = [[UINavigationController alloc] initWithRootViewController:viewController];
    debugNav.tabBarItem = [[UITabBarItem alloc] init];
    debugNav.tabBarItem.title = tabBarItemName;
    [debugNav.tabBarItem setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor lightGrayColor],
                                                   NSFontAttributeName : [UIFont systemFontOfSize:30] }
                                       forState:UIControlStateNormal];
    [debugNav.tabBarItem setTitleTextAttributes:@{ NSForegroundColorAttributeName : self.mainColor,
                                                   NSFontAttributeName : [UIFont systemFontOfSize:30] }
                                       forState:UIControlStateSelected];
    return debugNav;
}

- (NSArray *)CatonLogger
{
    return [CCAppFluecyMonitor obtainFluencyLogs];
}

- (NSArray *)CrashLogger
{
    return [CCUncaughtExceptionHandler obtainCrashLogs];
}
@end
