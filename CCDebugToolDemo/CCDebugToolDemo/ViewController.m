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
#import "WebLogViewController.h"
#import "WebViewController.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray *dataArr;

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

    CGFloat y = imageView.frame.origin.y + imageView.frame.size.height + spacing;
    self.dataArr = @[ @"网页", @"网页LOG", @"Crash(奔溃)", @"卡顿", @"沙盒" ];
    self.tableView.frame = CGRectMake(0, y, self.view.bounds.size.width, self.view.bounds.size.height - y);
    [self.view addSubview:self.tableView];
}

#pragma mark -
#pragma mark :. handler event

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

#pragma mark -
#pragma mark :. UITableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifer = @"tableViewCellIdentifer";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifer];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *text = [self.dataArr objectAtIndex:indexPath.row];
    if ([text isEqualToString:@"网页"]) {
        [self.navigationController pushViewController:[WebViewController new] animated:YES];
    } else if ([text isEqualToString:@"网页LOG"]) {
        [self.navigationController pushViewController:[WebLogViewController new] animated:YES];
    } else if ([text isEqualToString:@"Crash(奔溃)"]) {
        [self.navigationController pushViewController:[CrashViewController new] animated:YES];
    } else if ([text isEqualToString:@"卡顿"]) {
        [self.navigationController pushViewController:[FluecyMonitorViewController new] animated:YES];
    } else if ([text isEqualToString:@"沙盒"]) {
        [self sandboxWrite];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)])
        [cell setSeparatorInset:UIEdgeInsetsZero];
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)])
        [cell setPreservesSuperviewLayoutMargins:NO];
    if ([cell respondsToSelector:@selector(setLayoutMargins:)])
        [cell setLayoutMargins:UIEdgeInsetsZero];

    cell.textLabel.text = [self.dataArr objectAtIndex:indexPath.row];

    NSInteger totalRows = [tableView numberOfRowsInSection:indexPath.section];
    if ((totalRows - indexPath.row) % 2 == 0) {
        cell.backgroundColor = [UIColor colorWithHue:2.0 / 3.0 saturation:0.02 brightness:0.95 alpha:0.65];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

#pragma mark -
#pragma mark :. getter/setter

- (UITableView *)tableView
{
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tableView.backgroundColor = [UIColor clearColor];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        if (@available(iOS 11.0, *))
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor clearColor];
        [tableView setTableFooterView:v];
        _tableView = tableView;
    }
    return _tableView;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
