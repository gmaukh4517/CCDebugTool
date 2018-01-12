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

#import "CCDebugHttpViewController.h"
#import "CCNetworkInfoViewController.h"
#import "CCDebugHttpDetailViewController.h"
#import "CCHTTPTableViewCell.h"
#import <pthread.h>

#import "CCNetworkRecorder.h"

static inline void cc_dispatch_async_on_main_queue(void (^block)(void))
{
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

@interface CCDebugHttpViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) UITableView *httpViewTableView;
@property (nonatomic, strong) NSArray *dataArray;

@property (nonatomic, assign) BOOL rowInsertInProgress;

@end

@implementation CCDebugHttpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initNavigation];
    [self initControl];
    [self updateTransactions];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initNavigation
{
    UILabel *titleText = [[UILabel alloc] initWithFrame:CGRectMake(([[UIScreen mainScreen] bounds].size.width - 120) / 2, 20, 120, 44)];
    titleText.backgroundColor = [UIColor clearColor];
    titleText.textColor = [UIColor whiteColor];
    titleText.textAlignment = NSTextAlignmentCenter;
    titleText.numberOfLines = 0;
    titleText.text = @"HTTP";
    self.navigationItem.titleView = titleText;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStyleDone target:self action:@selector(clearAction)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"网络" style:UIBarButtonItemStyleDone target:self action:@selector(networkViewController)];
}

- (void)networkViewController
{
    CCNetworkInfoViewController *viewController = [CCNetworkInfoViewController new];
    viewController.hidesBottomBarWhenPushed = YES;
    self.navigationController.topViewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"HTTP" style:UIBarButtonItemStylePlain target:self action:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)initControl
{
    CGRect frame = self.view.bounds;
    frame.size.height -= 50;

    UITableView *httpViewTableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    httpViewTableView.backgroundColor = [UIColor clearColor];
    httpViewTableView.delegate = self;
    httpViewTableView.dataSource = self;
    httpViewTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    httpViewTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [httpViewTableView registerClass:[CCHTTPTableViewCell class] forCellReuseIdentifier:@"CCHTTPTableViewCellIdentifier"];
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
    [[CCNetworkRecorder defaultRecorder] clearRecordedActivity];
    self.dataArray = nil;
    [self.httpViewTableView reloadData];
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

    for (CCHTTPTableViewCell *cell in [self.httpViewTableView visibleCells]) {
        if ([cell.transaction isEqual:transaction]) {
            [cell setNeedsLayout];
            break;
        }
    }
    [self updateNavigation];
}

#pragma mark -
#pragma mark :. Logic handle

- (void)updateTransactions
{
    self.dataArray = [[CCNetworkRecorder defaultRecorder] networkTransactions];
    [self updateNavigation];
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
- (void)updateNavigation
{
    __block double flowCount = 0;
    [self.dataArray enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        flowCount += [obj expectedContentLength];
    }];

    if (!flowCount) {
        flowCount = 0.0;
    }

    cc_dispatch_async_on_main_queue(^() {
        NSMutableDictionary *flowDic = [NSMutableDictionary dictionaryWithDictionary:[UINavigationBar appearance].titleTextAttributes];
        [flowDic setObject:[UIFont systemFontOfSize:12.0] forKey:NSFontAttributeName];

        NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:@"HTTP\n"
                                                                                        attributes:[UINavigationBar appearance].titleTextAttributes];

        NSMutableAttributedString *flowCountString = [[NSMutableAttributedString alloc] initWithString:[self dataSize:flowCount]
                                                                                            attributes:flowDic];

        NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] init];
        [attrText appendAttributedString:titleString];
        [attrText appendAttributedString:flowCountString];

        UILabel *titleText = (UILabel *)self.navigationItem.titleView;
        titleText.attributedText = attrText;

        //        [self.httpViewTableView reloadData];

    });
}

#define KB (1024)
#define MB (KB * 1024)
#define GB (MB * 1024)
- (NSString *)dataSize:(NSInteger)n
{
    NSString *value;
    if (n < KB) {
        value = [NSString stringWithFormat:@"流量共%ziB", n];
    } else if (n < MB) {
        value = [NSString stringWithFormat:@"流量共%.2fKB", (float)n / (float)KB];
    } else if (n < GB) {
        value = [NSString stringWithFormat:@"流量共%.2fMB", (float)n / (float)MB];
    } else {
        value = [NSString stringWithFormat:@"流量共%.2fG", (float)n / (float)GB];
    }
    return value;
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
    return 55;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifer = @"CCHTTPTableViewCellIdentifier";
    CCHTTPTableViewCell *cell = (CCHTTPTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifer];
    [cell cc_cellWillDisplayWithModel:[self.dataArray objectAtIndex:indexPath.row]];
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
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    CCDebugHttpDetailViewController *viewController = [[CCDebugHttpDetailViewController alloc] init];
    viewController.hidesBottomBarWhenPushed = YES;
    viewController.detail = [self.dataArray objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
