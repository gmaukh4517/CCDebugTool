


//
//  CCNetworkInfoViewController.m
//  CCDebugTool
//
//  Created by CC on 2018/1/12.
//  Copyright © 2018年 CC. All rights reserved.
//

#import "CCNetworkInfoViewController.h"
#import "CCDebugTool.h"
#import "CCNetworkInfo.h"

@interface CCNetworkInfoViewController () <UITableViewDelegate, UITableViewDataSource, CCNetworkInfoDelegate>

@property (nonatomic, strong) UITableView *networkDetailTableView;
@property (nonatomic, strong) NSArray *dataArr;

@property (nonatomic, strong) CCNetworkInfo *network;
@property (nonatomic, strong) CCNetworkinfoEntity *networkInfo;

@end

@implementation CCNetworkInfoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Network";

    [self initControl];
    [self initLoadData];
}

- (void)initControl
{
    self.network = [[CCNetworkInfo alloc] init];
    self.network.delegate = self;
    self.networkInfo = [self.network populateNetworkInfo];
}

- (void)initLoadData
{
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:@{ @"网络类型" : self.networkInfo.readableInterface }];
    [array addObject:@{ @"网络名称" : self.networkInfo.networkName }];
    [array addObject:@{ @"外网地址" : self.networkInfo.externalIPAddress }];
    [array addObject:@{ @"内网地址" : self.networkInfo.internalIPAddress }];
    [array addObject:@{ @"子网地址" : self.networkInfo.netmask }];
    [array addObject:@{ @"路由地址" : self.networkInfo.routerAddress }];
    [array addObject:@{ @"广播地址" : self.networkInfo.broadcastAddress }];
    [array addObject:@{ @"代理地址" : self.networkInfo.proxyAddress }];

    _dataArr = array;

    [self.networkDetailTableView reloadData];
}

- (void)networkStatusUpdated
{
    [self initLoadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifer = @"httpDetailIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifer];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = [CCDebugTool manager].mainColor;
    }

    cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:15];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [[self.dataArr objectAtIndex:indexPath.row] allKeys].lastObject;
    cell.textLabel.text = key;
    NSString *value = [[self.dataArr objectAtIndex:indexPath.row] objectForKey:key];
    cell.detailTextLabel.text = value;

    cell.accessoryType = UITableViewCellAccessoryNone;

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

- (UITableView *)networkDetailTableView
{
    if (!_networkDetailTableView) {
        _networkDetailTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _networkDetailTableView.backgroundColor = [UIColor clearColor];
        _networkDetailTableView.delegate = self;
        _networkDetailTableView.dataSource = self;
        _networkDetailTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _networkDetailTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:_networkDetailTableView];

        if (@available(iOS 11.0, *))
            _networkDetailTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor clearColor];
        [_networkDetailTableView setTableFooterView:v];
    }
    return _networkDetailTableView;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
