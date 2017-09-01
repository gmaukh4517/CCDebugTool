//
//  ViewController.m
//  CCDebugToolDemo
//
//  Created by CC on 2017/9/1.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "ViewController.h"
#import "CrashViewController.h"
#import "FluecyMonitorViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 150) / 2, 20, 150, 150)];
    [self.view addSubview:_imageView = imageView];
    
    UIButton *loadButton = [[UIButton alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 100) / 2, 0, 120, 40)];
    [loadButton setTitle:@"Loading(图片)" forState:UIControlStateNormal];
    [loadButton setBackgroundColor:[UIColor blackColor]];
    [loadButton addTarget:self action:@selector(loadImage) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:loadButton];
    
    [self networkRequest];
    
    UIButton *crashButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 200, 120, 100)];
    [crashButton setTitle:@"Crash(奔溃)" forState:UIControlStateNormal];
    [crashButton setBackgroundColor:[UIColor blackColor]];
    [crashButton addTarget:self action:@selector(crashClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:crashButton];
    
    UIButton *lockButton = [[UIButton alloc] initWithFrame:CGRectMake(200, 200, 120, 100)];
    [lockButton setTitle:@"卡顿" forState:UIControlStateNormal];
    [lockButton setBackgroundColor:[UIColor blackColor]];
    [lockButton addTarget:self action:@selector(lockAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:lockButton];
}

- (void)loadImage
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [NSURL URLWithString:@"http://i4.piimg.com/1949/5168b8eac3e86977.jpg"];
        NSData *data = [[NSData alloc] initWithContentsOfURL:url];
        UIImage *image = [[UIImage alloc] initWithData:data];
        if (data != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = image;
            });
        }
    });
}

- (void)crashClick
{
    [self.navigationController pushViewController:[CrashViewController new] animated:YES];
}

- (void)lockAction
{
    [self.navigationController pushViewController:[FluecyMonitorViewController new] animated:YES];
}


- (void)networkRequest
{
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
