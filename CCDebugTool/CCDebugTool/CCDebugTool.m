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
#import "CCLogMonitoring.h"

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
    //    [[[UIApplication sharedApplication].delegate window] makeKeyWindow];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect frame = self.frame;
    if (@available(iOS 11.0, *)) {
        if (!UIEdgeInsetsEqualToEdgeInsets([UIApplication sharedApplication].keyWindow.safeAreaInsets, UIEdgeInsetsZero)) {
            frame.origin.y = 30;
        }
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

        self.debugWindow = [[CCDebugWindow alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width - 150) / 2, 0, 150, 20)];
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

    UIButton *debugButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 150, 22)];
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
    [[CCLogMonitoring manager] startMonitoring];
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
        self.debugTabBar = [[UITabBarController alloc] init];
        self.debugTabBar.tabBar.tintColor = self.mainColor;


        [self initializationNav:[CCDebugHttpViewController new] title:@"HTTP" imageNamed:@"tabbar_http" selectedImage:@"tabbar_http_yes"];
        [self initializationNav:[CCDebugLogViewController new] title:@"LOG" imageNamed:@"tabbar_log" selectedImage:@"tabbar_log_yes"];
        [self initializationNav:[CCMemoryProfilerViewController new] title:@"Cycle" imageNamed:@"tabbar_cycle" selectedImage:@"tabbar_cycle_yes"];
        [self initializationNav:[ToolViewController new] title:@"TOOL" imageNamed:@"tabbar_tool" selectedImage:@"tabbar_tool_yes"];
        //        UINavigationController *debugMonitorNav = [self initializationNav:[CCMonitorViewController new] tabBarItemName:@"Monitor"];

        UIViewController *rootViewController = [[[UIApplication sharedApplication].windows firstObject] rootViewController];
        UIViewController *presentedViewController = rootViewController.presentedViewController;
        [presentedViewController ?: rootViewController presentViewController:self.debugTabBar animated:YES completion:nil];
    } else {
        [self.debugTabBar dismissViewControllerAnimated:YES completion:nil];
        self.debugTabBar = nil;
    }
}

- (void)initializationNav:(UIViewController *)viewController title:(NSString *)title imageNamed:(NSString *)imageNamed selectedImage:(NSString *)selectedImage
{
    UINavigationController *debugNav = [[UINavigationController alloc] initWithRootViewController:viewController];
    debugNav.navigationItem.title = title;
    debugNav.tabBarItem.title = title;
    debugNav.tabBarItem.image = [[CCDebugTool tabbarImage:imageNamed] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    debugNav.tabBarItem.selectedImage = [[CCDebugTool tabbarImage:selectedImage] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [debugNav.navigationBar setBarTintColor:self.mainColor];
    [debugNav.navigationBar setTintColor:[UIColor whiteColor]];
    NSMutableDictionary *Attributes = [NSMutableDictionary dictionaryWithDictionary:[UINavigationBar appearance].titleTextAttributes];
    [Attributes setObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    [debugNav.navigationBar setTitleTextAttributes:Attributes];

    [self.debugTabBar addChildViewController:debugNav];
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
@end
