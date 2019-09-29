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
#import "WebViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"CCDebugDemo";

    CGFloat spacing = 10;

    UIButton *loadButton = [[UIButton alloc] initWithFrame:CGRectMake(spacing, spacing, 120, 40)];
    [loadButton setTitle:@"Loading(图片)" forState:UIControlStateNormal];
    [loadButton setBackgroundColor:[UIColor blackColor]];
    [loadButton addTarget:self action:@selector(loadImage) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:loadButton];

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(loadButton.frame.origin.x + loadButton.frame.size.width + spacing, 0, 150, 150)];
    imageView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_imageView = imageView];

    NSInteger rowNumber = 4;
    CGFloat x = spacing, y = imageView.frame.origin.y + imageView.frame.size.height + spacing;
    CGFloat width = (self.view.bounds.size.width - 10 * (rowNumber + 1)) / rowNumber;

    NSArray *arr = @[ @"网页", @"Crash(奔溃)", @"卡顿", @"沙盒" ];
    for (NSInteger i = 0; i < arr.count; i++) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, width)];
        [button setTitle:[arr objectAtIndex:i] forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor redColor]];
        button.tag = i;
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];

        x = button.frame.origin.x + button.frame.size.width + spacing;
        if ((i + 1) % rowNumber == 0) {
            x = spacing;
            y += button.bounds.size.height + spacing;
        }
        NSLog(@"%@",button.currentTitle);
    }
}

- (void)buttonClick:(UIButton *)sender
{
    if (sender.tag == 0) {
        [self.navigationController pushViewController:[WebViewController new] animated:YES];
    } else if (sender.tag == 1) {
        [self.navigationController pushViewController:[CrashViewController new] animated:YES];
    } else if (sender.tag == 2) {
        [self.navigationController pushViewController:[FluecyMonitorViewController new] animated:YES];
    } else if (sender.tag == 3) {
        [self sandboxWrite];
    }
}

- (void)sandboxWrite
{
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
//    NSFileManager *fileManger = [NSFileManager defaultManager];

    //    if (![fileManger fileExistsAtPath:path])
    //        [fileManger createFileAtPath:path contents:[NSData data] attributes:nil];

    NSArray *arr = @[ @".bundle", @".xlsx", @".txt", @".png", @".log", @".mp3", @".plist", @".pptx", @".sqlite", @".docx", @".zip", @".pdf" ];
    for (NSString *extend in arr) {
        NSString *fileName = [NSString stringWithFormat:@"/%@%@", [self randomString], extend];
        [@"Sandbox example" writeToFile:[path stringByAppendingString:fileName] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

/** 随机 数字 字母 **/
- (NSString *)randomString
{
    NSString *randomStr = [[NSString alloc] init];
    for (int i = 0; i < 15; i++) {
        int number = arc4random() % 36;
        if (number < 10)
            randomStr = [randomStr stringByAppendingString:[NSString stringWithFormat:@"%d", arc4random() % 10]];
        else
            randomStr = [randomStr stringByAppendingString:[NSString stringWithFormat:@"%c", (char)(arc4random() % 26) + 97]];
    }
    return randomStr.uppercaseString;
}

/** 随机 汉字 数字 字母 **/
- (NSString *)randomStringWithCount:(NSInteger)count
{
    NSString *randomStr = [[NSString alloc] init];
    for (NSInteger i = 0; i < count; i++) {
        NSInteger index = arc4random() % 3;
        if (index == 0) {
            NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
            NSInteger randomH = 0xA1 + arc4random() % (0xFE - 0xA1 + 1);
            NSInteger randomL = 0xB0 + arc4random() % (0xF7 - 0xB0 + 1);

            NSInteger number = (randomH << 8) + randomL;
            NSData *data = [NSData dataWithBytes:&number length:2];
            NSString *string = [[NSString alloc] initWithData:data encoding:gbkEncoding];
            randomStr = [randomStr stringByAppendingString:string];
        } else if (index == 1) {
            randomStr = [randomStr stringByAppendingString:[NSString stringWithFormat:@"%d", arc4random() % 10]];
        } else if (index == 2) {
            randomStr = [randomStr stringByAppendingString:[NSString stringWithFormat:@"%c", (char)(arc4random() % 26) + 97]];
        }
    }
    return randomStr;
}

- (void)loadImage
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1569746170874&di=7e0114ce23fffb85e0e1a334a6e592a8&imgtype=0&src=http%3A%2F%2Fb-ssl.duitang.com%2Fuploads%2Fitem%2F201612%2F02%2F20161202132302_UFcmC.jpeg"];
        NSData *data = [[NSData alloc] initWithContentsOfURL:url];
        UIImage *image = [[UIImage alloc] initWithData:data];
        if (data != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = image;
            });
        }
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
