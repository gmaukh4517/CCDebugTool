//
//  AppDelegate.m
//  CCDebugToolDemo
//
//  Created by CC on 2017/9/1.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "AppDelegate.h"
#import "DebugRequestProtocol.h"
#import "ViewController.h"

#if __has_include(<CCDebugTool/CCDebugTool.h>)
#import <CCDebugTool/CCDebugTool.h>
#endif


@interface AppDelegate ()

@property (nonatomic, strong) NSMutableArray *connections;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self setUpNavigationBarAppearance:[UIColor colorWithRed:0.223 green:0.698 blue:1 alpha:1.f]];
#ifdef CCDebugTool_h
    [[CCDebugTool manager] enableDebugMode];
#endif

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[ViewController new]];
    [self.window makeKeyAndVisible];

    [[DebugRequestProtocol new] sendExampleNetworkRequests];

    return YES;
}

- (void)setUpNavigationBarAppearance:(UIColor *)color
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        [[UINavigationBar appearance] setBarTintColor:color];
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
        UIImage *backButtonImage = [[UIImage imageNamed:@"nav_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [[UINavigationBar appearance] setBackIndicatorImage:backButtonImage];
        [[UINavigationBar appearance] setBackIndicatorTransitionMaskImage:backButtonImage];
    } else {
        [[UINavigationBar appearance] setTintColor:color];
    }

    [[UINavigationBar appearance] setTranslucent:NO];

    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [UIColor whiteColor], NSForegroundColorAttributeName, [UIFont systemFontOfSize:18], NSFontAttributeName, nil]];

    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:16], NSFontAttributeName, nil] forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:16], NSFontAttributeName, nil] forState:UIControlStateSelected];
    if (@available(iOS 11.0, *))
        [[UIScrollView appearance] setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
