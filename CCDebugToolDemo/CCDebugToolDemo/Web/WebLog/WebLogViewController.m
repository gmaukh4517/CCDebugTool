//
//  WebLogViewController.m
//  CCDebugToolDemo
//
//  Created by CC on 2019/11/11.
//  Copyright © 2019 CC. All rights reserved.
//

#import "WebLogViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>


@interface CCDebugScriptMessageDelegate : NSObject <WKScriptMessageHandler>

@property (nonatomic, weak) id<WKScriptMessageHandler> scriptDelegate;

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate;

@end

@implementation CCDebugScriptMessageDelegate

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate
{
    self = [super init];
    if (self) {
        _scriptDelegate = scriptDelegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    [self.scriptDelegate userContentController:userContentController didReceiveScriptMessage:message];
}

@end


@interface WebLogViewController () <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *wkWebView;

@property (nonatomic, strong) UIWebView *webView;

@end

@implementation WebLogViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithHue:2.0 / 3.0 saturation:0.02 brightness:0.95 alpha:0.65];
    self.title = @"test Log";

    [self.wkWebView loadHTMLString:[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"WebTest" ofType:@"html"]
                                                             encoding:NSUTF8StringEncoding
                                                                error:nil]
                           baseURL:[[NSBundle mainBundle] bundleURL]];

    [self.webView loadHTMLString:[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"WebTest" ofType:@"html"]
                                                           encoding:NSUTF8StringEncoding
                                                              error:nil]
                         baseURL:[[NSBundle mainBundle] bundleURL]];

    [self.view addSubview:self.wkWebView];
    [self.view addSubview:self.webView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGFloat height = (self.view.bounds.size.height - 10) / 2;

    CGRect frame = self.wkWebView.frame;
    frame.size.width = self.view.bounds.size.width;
    frame.size.height = height;
    self.wkWebView.frame = frame;

    frame = self.webView.frame;
    frame.origin.y = self.wkWebView.frame.origin.y + self.wkWebView.frame.size.height + 10;
    frame.size.width = self.view.bounds.size.width;
    frame.size.height = height;
    self.webView.frame = frame;
}

#pragma mark -
#pragma mark :. WKWebView
- (WKWebView *)wkWebView
{
    if (!_wkWebView) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];

        WKUserContentController *userCC = [WKUserContentController new];
        [userCC addScriptMessageHandler:[[CCDebugScriptMessageDelegate alloc] initWithDelegate:self]  name:@"demoWebView"];
        configuration.userContentController = userCC;

        _wkWebView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
        _wkWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        if ([_wkWebView respondsToSelector:@selector(setNavigationDelegate:)])
            [_wkWebView setNavigationDelegate:self];

        if ([_wkWebView respondsToSelector:@selector(setDelegate:)])
            [_wkWebView setUIDelegate:self];
    }
    return _wkWebView;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSLog(@"WebViewController name: %@ body: %@", message.name, message.body);
}

#pragma mark -
#pragma mark :. UIWebView

- (UIWebView *)webView
{
    if (!_webView) {
        UIWebView *webView = [UIWebView new];
        JSContext *context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
        context[ @"demoWebView" ] = ^(JSValue *message) {
            NSLog(@"UIWebView CCHookLog name: %@ body: %@", @"hahaha", message);
        };
        _webView = webView;
    }
    return _webView;
}
/*
 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
