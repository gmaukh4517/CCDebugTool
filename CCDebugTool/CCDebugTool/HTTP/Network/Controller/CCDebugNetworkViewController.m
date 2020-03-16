//
//  CCDebugHttpViewController.m
//  CCKit
//
// Copyright (c) 2015 CC ( https://github.com/gmaukh4517/CCKit )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "CCDebugNetworkViewController.h"
#import "CCDebugHttpDetailViewController.h"
#import "CCDebugTool.h"
#import "CCNetworkInfoViewController.h"
#import "CCNetworkRecorder.h"
#import "CCNetworkTableViewCell.h"
#import "CCServiceManagerViewController.h"
#import <pthread.h>

@interface CCDebugNetworkViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) UITableView *httpViewTableView;
@property (nonatomic, strong) NSArray *dataArray;

@property (nonatomic) long long bytesReceived;
@property (nonatomic, assign) BOOL rowInsertInProgress;

@end

@implementation CCDebugNetworkViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initNavigation];
    [self initControl];
    [self updateTransactions];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.httpViewTableView.frame = self.view.bounds;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initNavigation
{
    self.navigationItem.title = @"NetWork";

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(clearAction)];

    UIBarButtonItem *serviceBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"环境" style:UIBarButtonItemStyleDone target:self action:@selector(serviceConfigViewController)];
    UIBarButtonItem *networkBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"IP  " style:UIBarButtonItemStyleDone target:self action:@selector(networkViewController)];

    self.navigationItem.rightBarButtonItems = @[ networkBarButtonItem, serviceBarButtonItem ];
}

- (void)serviceConfigViewController
{
    CCServiceManagerViewController *viewController = [CCServiceManagerViewController new];
    viewController.hidesBottomBarWhenPushed = YES;
    [self pushCCNewViewController:viewController];
}

- (void)networkViewController
{
    CCNetworkInfoViewController *viewController = [CCNetworkInfoViewController new];
    viewController.hidesBottomBarWhenPushed = YES;
    [self pushCCNewViewController:viewController];
}

- (void)initControl
{
    CGRect frame = self.view.bounds;
    frame.size.height -= 50;

    UITableView *httpViewTableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    httpViewTableView.backgroundColor = [UIColor clearColor];
    httpViewTableView.delegate = self;
    httpViewTableView.dataSource = self;
    httpViewTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    httpViewTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [httpViewTableView registerClass:[CCNetworkTableViewCell class] forCellReuseIdentifier:@"CCNetworkTableViewCellIdentifier"];
    [self.view addSubview:self.httpViewTableView = httpViewTableView];

    if (@available(iOS 11.0, *)) {
        httpViewTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }

    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.backgroundColor = [UIColor clearColor];
    [httpViewTableView setTableFooterView:v];


    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewTransactionRecordedNotification:) name:kCCNetworkRecorderNewTransactionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTransactionUpdatedNotification:) name:kCCNetworkRecorderTransactionUpdatedNotification object:nil];
}

- (void)clearAction
{
    [self dismissViewControllerAnimated:YES completion:nil];

    //    [[CCNetworkRecorder defaultRecorder] clearRecordedActivity];
    //    self.dataArray = nil;
    //    [self.httpViewTableView reloadData];
}

#pragma mark -
#pragma mark :. Notification handle
- (void)handleNewTransactionRecordedNotification:(NSNotification *)notification
{
    [self tryUpdateTransactions];
}

- (void)handleTransactionUpdatedNotification:(NSNotification *)notification
{
    CCNetworkTransaction *transaction = notification.userInfo[ kCCNetworkRecorderUserInfoTransactionKey ];

    for (CCNetworkTableViewCell *cell in [self.httpViewTableView visibleCells]) {
        if ([cell.transaction isEqual:transaction]) {
            [cell setNeedsLayout];
            break;
        }
    }
    [self updateFirstSectionHeader];
}

- (NSString *)headerText
{
    NSString *headerText = nil;
    NSInteger totalRequests = self.dataArray.count;
    NSString *byteCountText = [NSByteCountFormatter stringFromByteCount:self.bytesReceived countStyle:NSByteCountFormatterCountStyleBinary];
    NSString *requestsText = totalRequests == 1 ? @"Request" : @"Requests";
    headerText = [NSString stringWithFormat:@"%ld %@ (%@ received)", (long)totalRequests, requestsText, byteCountText];

    return headerText;
}

#pragma mark -
#pragma mark :. Logic handle

- (void)updateTransactions
{
    self.dataArray = [[CCNetworkRecorder defaultRecorder] networkTransactions];
    [self updateFirstSectionHeader];
}

- (void)tryUpdateTransactions
{
    if (self.rowInsertInProgress) {
        return;
    }

    NSInteger existingRowCount = [self.dataArray count];
    [self updateTransactions];
    NSInteger newRowCount = [self.dataArray count];
    NSInteger addedRowCount = newRowCount - existingRowCount;

    if (addedRowCount != 0) {
        // Insert animation if we're at the top.
        if (self.httpViewTableView.contentOffset.y <= 0.0 && addedRowCount > 0) {
            [CATransaction begin];

            self.rowInsertInProgress = YES;
            [CATransaction setCompletionBlock:^{
                self.rowInsertInProgress = NO;
                [self tryUpdateTransactions];
            }];

            NSMutableArray *indexPathsToReload = [NSMutableArray array];
            for (NSInteger row = 0; row < addedRowCount; row++) {
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:row inSection:0]];
            }
            [self.httpViewTableView insertRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];

            [CATransaction commit];
        } else {
            // Maintain the user's position if they've scrolled down.
            CGSize existingContentSize = self.httpViewTableView.contentSize;
            [self.httpViewTableView reloadData];
            CGFloat contentHeightChange = self.httpViewTableView.contentSize.height - existingContentSize.height;
            self.httpViewTableView.contentOffset = CGPointMake(self.httpViewTableView.contentOffset.x, self.httpViewTableView.contentOffset.y + contentHeightChange);
        }
    }
}

/** 修改导航栏请求流量 **/
- (void)updateFirstSectionHeader
{
    long long bytesReceived = 0;
    for (CCNetworkTransaction *transaction in self.dataArray)
        bytesReceived += transaction.expectedContentLength;
    self.bytesReceived = bytesReceived;

    UIView *view = [self.httpViewTableView headerViewForSection:0];
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
        headerView.textLabel.text = [self headerText];
        [headerView setNeedsLayout];
    }
}

#pragma mark -
#pragma mark :. UITableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    return 0.1;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self headerText];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
        headerView.textLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifer = @"CCNetworkTableViewCellIdentifier";
    CCNetworkTableViewCell *cell = (CCNetworkTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifer];
    cell.transaction = [self.dataArray objectAtIndex:indexPath.row];
    return cell;
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

    NSInteger totalRows = [tableView numberOfRowsInSection:indexPath.section];
    if ((totalRows - indexPath.row) % 2 == 0) {
        cell.backgroundColor = [UIColor colorWithHue:2.0 / 3.0 saturation:0.02 brightness:0.95 alpha:0.65];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    CCDebugHttpDetailViewController *viewController = [[CCDebugHttpDetailViewController alloc] init];
    viewController.hidesBottomBarWhenPushed = YES;
    viewController.transaction = [self.dataArray objectAtIndex:indexPath.row];
    [self pushCCNewViewController:viewController];
}

@end
