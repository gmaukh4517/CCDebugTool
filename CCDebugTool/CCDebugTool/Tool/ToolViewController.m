//
//  ToolViewController.m
//  CCDebugTool
//
//  Created by CC on 2017/11/6.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "ToolViewController.h"
#import "CCDebugTool.h"

#import "CCSandboxViewController.h"
#import "CCPingViewController.h"
#import "CCSpeedTestViewController.h"
#import "CCCookiesViewController.h"
#import "DatabaseViewController.h"

@interface ToolViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tooTableView;

@property (nonatomic, strong) NSArray *dataArr;

@end

@implementation ToolViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initNavigation];
    [self initControl];
    [self initLoadData];
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

-(void)initLoadData
{
    self.dataArr = @[@{@"image":@"tool_sandbox",@"title" : @"Sandbox"},
                     @{@"image":@"tool_ping",@"title":@"Ping"},
                     @{@"image":@"tool_speedtest",@"title":@"SpeedTest"},
                     @{@"image":@"tool_cookies",@"title":@"Cookies"},
                     @{@"image":@"tool_database",@"title":@"Database"}];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifer];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.textColor = [CCDebugTool manager].mainColor;
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:19];
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
    if (indexPath.row == 0) {
        viewController = [CCSandboxViewController new];
    }else if (indexPath.row == 1){
        viewController = [CCPingViewController new];
    }else if (indexPath.row == 2){
        viewController = [CCSpeedTestViewController new];
    } else if (indexPath.row == 3){
        viewController = [CCCookiesViewController new];
    } else if (indexPath.row == 4){
        viewController = [DatabaseViewController new];
    }
    
    if (viewController){
         viewController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:viewController animated:YES];
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

-(UITableView *)tooTableView
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
