//
//  AppDelegate.m
//  CCDebugToolDemo
//
//  Created by CC on 2017/9/1.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import <CCDebugTool/CCDebugTool.h>

@interface AppDelegate () <NSURLConnectionDataDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSMutableArray *connections;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self navigationBarColor];
    [[CCDebugTool manager] enableDebugMode];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[ViewController new]];
    [self.window makeKeyAndVisible];
    
    [self sendExampleNetworkRequests];
    
    return YES;
}

- (void)navigationBarColor
{
    UIColor *color = [UIColor colorWithRed:27 / 255.f green:130 / 255.f blue:210 / 255.f alpha:1.f];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:color];
    
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [UIColor whiteColor], NSForegroundColorAttributeName, [UIFont boldSystemFontOfSize:19], NSFontAttributeName, nil]];
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

#pragma mark - Networking Example

- (void)sendExampleNetworkRequests
{
    // Async NSURLConnection
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://api.github.com/repos/gmaukh4517/CCDebugTool/issues"]] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
    }];
    
    // Sync NSURLConnection
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://lorempixel.com/320/480/"]] returningResponse:NULL error:NULL];
    });
    
    // NSURLSession
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 10.0;
    NSURLSession *mySession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    NSMutableArray *pendingTasks = [NSMutableArray array];
    
    // NSURLSessionDataTask with delegate
    [pendingTasks addObject:[mySession dataTaskWithURL:[NSURL URLWithString:@"http://cdn.flipboard.com/serviceIcons/v2/social-icon-flipboard-96.png"]]];
    
    // NSURLSessionDownloadTask with delegate
    [pendingTasks addObject:[mySession downloadTaskWithURL:[NSURL URLWithString:@"https://assets-cdn.github.com/images/icons/emoji/unicode/1f44d.png?v5"]]];
    
    // Async NSURLSessionDownloadTask
    [pendingTasks addObject:[[NSURLSession sharedSession] downloadTaskWithURL:[NSURL URLWithString:@"http://lorempixel.com/1024/1024/"] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        
    }]];
    
    // Async NSURLSessionDataTask
    [pendingTasks addObject:[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"https://api.github.com/emojis"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
    }]];
    
    // Async NSURLSessionUploadTask
    NSMutableURLRequest *uploadRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://google.com/"]];
    uploadRequest.HTTPMethod = @"POST";
    NSData *data = [@"q=test" dataUsingEncoding:NSUTF8StringEncoding];
    [pendingTasks addObject:[mySession uploadTaskWithRequest:uploadRequest fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
    }]];
    
    // Remaining requests made through NSURLConnection with a delegate
    NSArray *requestURLStrings = @[ @"http://lorempixel.com/400/400/",
                                    @"http://google.com",
                                    @"http://lorempixel.com/750/1334/" ];
    
    NSTimeInterval delayTime = 10.0;
    const NSTimeInterval stagger = 1.0;
    
    // Send off the NSURLSessionTasks (staggered)
    for (NSURLSessionTask *task in pendingTasks) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [task resume];
        });
        delayTime += stagger;
    }
    
    // Begin the NSURLConnection requests (staggered)
    self.connections = [NSMutableArray array];
    for (NSString *urlString in requestURLStrings) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
            [self.connections addObject:[[NSURLConnection alloc] initWithRequest:request delegate:self]];
        });
        delayTime += stagger;
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    completionHandler(NSURLSessionResponseAllow);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.connections removeObject:connection];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.connections removeObject:connection];
}


@end
