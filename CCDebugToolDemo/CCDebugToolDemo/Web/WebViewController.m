//
//  WebViewController.m
//  CCDebugToolDemo
//
//  Created by CC on 2019/8/19.
//  Copyright © 2019 CC. All rights reserved.
//

#import "WebViewController.h"
#import <WebKit/WebKit.h>

@interface WebViewController ()

@property (nonatomic, strong) WKWebView *wkWebView;

@end

@implementation WebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"请求监听";
    self.view.backgroundColor = [UIColor colorWithHue:2.0 / 3.0 saturation:0.02 brightness:0.95 alpha:0.65];
    [self.view addSubview:self.wkWebView];
}


#pragma mark -
#pragma mark :. WKWebView
- (WKWebView *)wkWebView
{
    if (!_wkWebView) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        configuration.userContentController = [WKUserContentController new];

        _wkWebView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
        _wkWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        NSURL *url = [NSURL URLWithString:@"https://www.baidu.com/"];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [_wkWebView loadRequest:request];
    }
    return _wkWebView;
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
