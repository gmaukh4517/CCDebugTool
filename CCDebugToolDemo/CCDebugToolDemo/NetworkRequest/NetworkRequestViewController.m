//
//  NetworkRequestViewController.m
//  CCDebugToolDemo
//
//  Created by CC on 2017/11/9.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "NetworkRequestViewController.h"

@interface NetworkRequestViewController () 

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation NetworkRequestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *loadButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 120, 40)];
    [loadButton setTitle:@"Loading(图片)" forState:UIControlStateNormal];
    [loadButton setBackgroundColor:[UIColor blackColor]];
    [loadButton addTarget:self action:@selector(loadImage) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:loadButton];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(loadButton.frame.origin.x + loadButton.frame.size.width + 10, 0, 150, 150)];
    imageView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_imageView = imageView];
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



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
