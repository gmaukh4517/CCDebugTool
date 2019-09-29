//
//  ToolViewController.m
//  CCDebugTool
//
//  Created by CC on 2017/11/6.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "ToolViewController.h"
#import "CCDebugTool.h"

#import "BundleDirectoryViewController.h"
#import "CCCookiesViewController.h"
#import "CCDebugKeychainViewController.h"
#import "CCPingViewController.h"
#import "CCSandboxViewController.h"
#import "CCSpeedTestViewController.h"
#import "DatabaseViewController.h"

@interface ToolTableViewCell : UITableViewCell

@end


@interface ToolViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tooTableView;

@property (nonatomic, strong) NSArray *dataArr;

@end

@implementation ToolViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self initNavigation];
    [self initControl];
    [self initLoadData];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.tooTableView.frame = self.view.bounds;
}

- (void)initNavigation
{
    self.navigationItem.title = @"工具";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(dismissViewController)];
}

- (void)initControl
{
    [self.view addSubview:self.tooTableView];
}

- (void)initLoadData
{
    self.dataArr = @[ @{ @"image" : @"tool_sandbox",
                         @"title" : @"Sandbox" },
                      @{ @"image" : @"tool_bundle",
                         @"title" : @"Bundle Directory" },
                      @{ @"image" : @"tool_ping",
                         @"title" : @"Ping" },
                      @{ @"image" : @"tool_speedtest",
                         @"title" : @"SpeedTest" },
                      @{ @"image" : @"tool_cookies",
                         @"title" : @"Cookies" },
                      @{ @"image" : @"tool_database",
                         @"title" : @"Database" },
                      @{ @"image" : @"tool_keychain",
                         @"title" : @"Keychain" },
                      @{ @"image" : @"tool_uidebug",
                         @"title" : @"UIDebugging" } ];
}

#pragma mark -
#pragma mark :. event handle
- (void)dismissViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifer = @"TooTableViewCellIdentifer";
    ToolTableViewCell *cell = (ToolTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell) {
        cell = [[ToolTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifer];
    }

    NSDictionary *item = [self.dataArr objectAtIndex:indexPath.row];

    cell.textLabel.text = [item objectForKey:@"title"];
    cell.imageView.image = [CCDebugTool cc_bundle:[item objectForKey:@"image"] inDirectory:@"tool"];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UIViewController *viewController;
    NSString *pushName = [[self.dataArr objectAtIndex:indexPath.row] objectForKey:@"title"];
    if ([pushName isEqualToString:@"Sandbox"]) {
        viewController = [CCSandboxViewController new];
    } else if ([pushName isEqualToString:@"Ping"]) {
        viewController = [CCPingViewController new];
    } else if ([pushName isEqualToString:@"SpeedTest"]) {
        viewController = [CCSpeedTestViewController new];
    } else if ([pushName isEqualToString:@"Cookies"]) {
        viewController = [CCCookiesViewController new];
    } else if ([pushName isEqualToString:@"Database"]) {
        viewController = [DatabaseViewController new];
    } else if ([pushName isEqualToString:@"Bundle Directory"]) {
        viewController = [[BundleDirectoryViewController alloc] initWithPath:NSBundle.mainBundle.bundlePath];
    } else if ([pushName isEqualToString:@"Keychain"]) {
        viewController = [CCDebugKeychainViewController new];
    } else if ([pushName isEqualToString:@"UIDebugging"]) {
        [CCDebugTool performSelector:NSSelectorFromString(@"toggleVisibility") withObject:nil];
    }

    if (viewController) {
        viewController.hidesBottomBarWhenPushed = YES;
        [self pushNewViewController:viewController];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark -
#pragma mark :. getter/setter

- (UITableView *)tooTableView
{
    if (!_tooTableView) {
        CGRect TableViewFrame = self.view.bounds;
        TableViewFrame.size.height = self.view.bounds.size.height - 64 - 50;

        UITableView *tooTableView = [[UITableView alloc] initWithFrame:TableViewFrame style:UITableViewStylePlain];
        tooTableView.backgroundColor = [UIColor clearColor];
        tooTableView.delegate = self;
        tooTableView.dataSource = self;
        tooTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        tooTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:_tooTableView = tooTableView];

        if (@available(iOS 11.0, *))
            tooTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor clearColor];
        [tooTableView setTableFooterView:v];
    }
    return _tooTableView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

@implementation ToolTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        self.imageView.layer.borderColor = UIColor.blackColor.CGColor;

        self.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
        self.textLabel.textColor = [CCDebugTool manager].mainColor;

        self.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10];
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    const CGFloat kLeftPadding = 10.0;

    CGRect imageViewFrame = self.imageView.frame;
    CGFloat thumbnailOriginY = round((self.contentView.bounds.size.height - imageViewFrame.size.height) / 2.0);
    imageViewFrame.origin.x = kLeftPadding;
    imageViewFrame.origin.y = thumbnailOriginY;
    self.imageView.frame = imageViewFrame;

    CGRect textLabelFrame = self.textLabel.frame;
    textLabelFrame.origin.x = imageViewFrame.origin.x + imageViewFrame.size.width + kLeftPadding;
    self.textLabel.frame = textLabelFrame;
}


@end
