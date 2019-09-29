//
//  DebugRequestProtocol.m
//  CCDebugToolDemo
//
//  Created by CC on 2019/9/10.
//  Copyright © 2019 CC. All rights reserved.
//

#import "DebugRequestProtocol.h"

#if __has_include(<CCDebugTool/CCDebugTool.h>)
#import <CCDebugTool/CCDebugTool.h>

#define configServiceAddress [[[CCDebugTool manager] getServiceParameter] objectForKey:@"ServiceAddress"] ?: ServiceAddress

#else

#define configServiceAddress ServiceAddress =

#endif

@interface DebugRequestProtocol () <NSURLConnectionDataDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSMutableArray *connections;

@end

@implementation DebugRequestProtocol

#ifdef CCDebugTool_h
+ (void)load
{
    [super load];

    NSMutableArray *parameters = [NSMutableArray array];

    [parameters addObject:@{ @"id" : @"1",
                             @"title" : @"测试环境",
                             @"parameter" : @{@"ServiceAddress" : @"测试环境"} }];

    [parameters addObject:@{ @"id" : @"2",
                             @"title" : @"正式环境",
                             @"parameter" : @{@"ServiceAddress" : @"正式环境"} }];

    [[CCDebugTool manager] setServiceParameters:parameters];
}

#endif

- (void)sendExampleNetworkRequests
{
    // Async NSURLConnection
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://api.github.com/repos/gmaukh4517/CCDebugTool/issues"]]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError){

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
    [pendingTasks addObject:[[NSURLSession sharedSession] downloadTaskWithURL:[NSURL URLWithString:@"http://lorempixel.com/1024/1024/"]
                                                            completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error){

    }]];

    // Async NSURLSessionDataTask
    [pendingTasks addObject:[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"https://api.github.com/emojis"]
                                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){

    }]];

    // Async NSURLSessionUploadTask
    NSMutableURLRequest *uploadRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://google.com/"]];
    uploadRequest.HTTPMethod = @"POST";
    NSData *data = [@"q=test" dataUsingEncoding:NSUTF8StringEncoding];
    [pendingTasks addObject:[mySession uploadTaskWithRequest:uploadRequest
                                                    fromData:data
                                           completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){

    }]];

    NSTimeInterval delayTime = 10.0;
    const NSTimeInterval stagger = 1.0;

    // Send off the NSURLSessionTasks (staggered)
    for (NSURLSessionTask *task in pendingTasks) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [task resume];
        });
        delayTime += stagger;
    }

    // Remaining requests made through NSURLConnection with a delegate
    NSArray *requestURLStrings = @[ @"http://lorempixel.com/400/400/",
                                    @"http://google.com",
                                    @"http://search.cocoapods.org/api/pods?query=CCDebugTool&amount=1",
                                    @"https://api.github.com/users/gmaukh4517/repos",
                                    @"http://info.cern.ch/hypertext/WWW/TheProject.html",
                                    @"https://api.github.com/repos/gmaukh4517/CCDebugTool/issues",
                                    @"https://cloud.githubusercontent.com/assets/516562/3971767/e4e21f58-27d6-11e4-9b07-4d1fe82b80ca.png",
                                    @"http://hipsterjesus.com/api?paras=1&type=hipster-centric&html=false",
                                    @"http://lorempixel.com/750/1334/" ];

    // Begin the NSURLConnection requests (staggered)
    self.connections = [NSMutableArray array];
    for (NSString *urlString in requestURLStrings) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
            [self.connections addObject:[[NSURLConnection alloc] initWithRequest:request delegate:self]];
        });
        delayTime += stagger;
    }

    NSURLSession *session = [NSURLSession sharedSession];
    __block NSString *result = nil;
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.baidu.com"]]
                                                completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        if (!error) { //没有错误，返回正确；
            result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"返回正确：%@", result);
        } else {
            NSLog(@"错误信息：%@", error); //出现错误；
        }
    }];
    [dataTask resume];
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
