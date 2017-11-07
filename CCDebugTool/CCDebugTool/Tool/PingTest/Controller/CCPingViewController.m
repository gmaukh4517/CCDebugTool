//
//  CCPingViewController.m
//  CCDebugTool
//
//  Created by CC on 2017/11/3.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCPingViewController.h"
#import "CCPingTextView.h"
#import "CCPingServices.h"

@interface CCPingViewController ()

@property (nonatomic, weak) UITextField *textField;
@property (nonatomic, weak) CCPingTextView *textView;
@property (nonatomic, strong) CCPingServices *pingServices;

@end

@implementation CCPingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initNavigation];
    [self initControl];
}

- (void)initNavigation
{
    self.navigationItem.title = @"PING 网络";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearDebugViewActionFired:)];
    if ([UIViewController instancesRespondToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout  = UIRectEdgeNone;
    }
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)initControl
{
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, CGRectGetWidth(self.view.frame) - 100, 30)];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.placeholder = @"请输入IP地址或者域名";
    textField.text = @"www.baidu.com";
    [self.view addSubview:_textField = textField];
    
    UIButton *pingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    pingButton.frame = CGRectMake(CGRectGetMaxX(textField.frame) + 10, 10, 60, 30);
    [pingButton setTitle:@"Ping" forState:UIControlStateNormal];
    [pingButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [pingButton addTarget:self action:@selector(pingButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pingButton];
    
    CCPingTextView *textView = [[CCPingTextView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(textField.frame) + 10, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetMaxY(textField.frame) - 10)];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.font = [UIFont systemFontOfSize:13];
    textView.editable = NO;
    [self.view addSubview:_textView = textView];
}

- (void)pingButtonClick:(UIButton *)button {
    [self.textField resignFirstResponder];
    if (!button.selected) {
        __weak typeof(self) weakself = self;
        [button setTitle:@"Stop" forState:UIControlStateNormal];
        button.selected = YES;
        self.pingServices = [CCPingServices startPingAddress:self.textField.text callbackHandler:^(CCPingItem *pingItem, NSArray *pingItems) {
            if (pingItem.status != CCPingStatusFinished) {
                [weakself.textView appendText:pingItem.description];
            } else {
                [weakself.textView appendText:[CCPingItem statisticsWithPingItems:pingItems]];
                [button setTitle:@"Ping" forState:UIControlStateNormal];
                button.selected = NO;
                weakself.pingServices = nil;
            }
        }];
    } else {
        [self.pingServices cancel];
    }
    
}

#pragma mark -
#pragma mark :. event handle

- (void)clearDebugViewActionFired:(id)sender {
    self.textView.text = nil;
}

- (void)dealloc {
    [self.pingServices cancel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
