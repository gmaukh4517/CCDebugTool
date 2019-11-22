//
//  CCDebugLogViewController.m
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

#import "CCDebugLogViewController.h"
#import "CCDebugContentViewController.h"
#import "CCDebugDataSource.h"
#import "CCDebugTool.h"
#import "CCStatisticsViewController.h"

@interface CCDebugLogViewController () <UITableViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) CCDebugDataSource *dataSource;

@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, copy) NSArray *itemTitle;

@end

@implementation CCDebugLogViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initNavigation];
    [self initControl];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.scrollView.frame = self.view.bounds;

    [self.scrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        CGRect frame = obj.frame;
        frame.size.height = self.view.bounds.size.height;
        obj.frame = frame;
    }];
}

- (void)initNavigation
{
    _itemTitle = @[ @"Crash", @"Caton", @"LOG", @"Operate" ];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:_itemTitle];
    segmentedControl.selectedSegmentIndex = 0;
    segmentedControl.clipsToBounds = YES;
    segmentedControl.tintColor = self.navigationController.navigationBar.tintColor;
    segmentedControl.frame = CGRectMake(0, 0, 200, 30);
    segmentedControl.momentary = NO;
    [segmentedControl addTarget:self action:@selector(didSegmentedControl:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = segmentedControl;
    self.navigationItem.title = [_itemTitle objectAtIndex:0];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(dismissViewController)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"统计" style:UIBarButtonItemStyleDone target:self action:@selector(rightBarButtonItemClick:)];

    self.currentIndex = -1;
    [self reloadData:0];
}

- (void)rightBarButtonItemClick:(UIBarButtonItem *)sender
{
    [self pushCCNewViewController:[CCStatisticsViewController new]];
}

- (void)didSegmentedControl:(UISegmentedControl *)sender
{
    [self reloadData:sender.selectedSegmentIndex];

    [UIView animateWithDuration:0.5
                     animations:^{
        CGPoint offset = self.scrollView.contentOffset;
        offset.x = self.scrollView.frame.size.width * sender.selectedSegmentIndex;
        self.scrollView.contentOffset = offset;
    }];
}

- (void)dismissViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)initControl
{
    self.view.backgroundColor = [UIColor whiteColor];

    _dataSource = [[CCDebugDataSource alloc] init];
    _dataSource.sourceType = CCDebugDataSourceTypeCrash;

    UIScrollView *scrollview = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollview.pagingEnabled = YES;
    scrollview.showsHorizontalScrollIndicator = NO;
    //    scrollview.showsVerticalScrollIndicator = NO;
    scrollview.bounces = NO;
    scrollview.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    scrollview.delegate = self;
    scrollview.contentSize = CGSizeMake(scrollview.frame.size.width * self.itemTitle.count, 0);
    [self.view addSubview:_scrollView = scrollview];

    if (@available(iOS 11.0, *)) {
        scrollview.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }

    for (NSInteger i = 0; i < self.itemTitle.count; i++) {
        UITableView *tableView = [self createTableView:self.view.frame.size.width * i];
        tableView.tag = [[NSString stringWithFormat:@"%d000", (int)i + 1] integerValue];
        [scrollview addSubview:tableView];
    }
}

#pragma mark -
#pragma mark :. handel

- (void)reloadData:(NSInteger)selectIndex
{
    if (selectIndex != self.currentIndex) {
        self.currentIndex = selectIndex;
        self.navigationItem.title = [_itemTitle objectAtIndex:selectIndex];
        UISegmentedControl *segmentedControl = (UISegmentedControl *)self.navigationItem.titleView;
        [segmentedControl setSelectedSegmentIndex:selectIndex];
        if (selectIndex == 0) {
            UITableView *tableView = [_scrollView viewWithTag:1000];
            _dataSource.sourceType = CCDebugDataSourceTypeCrash;
            tableView.scrollEnabled = YES;
            [tableView reloadData];
        } else if (selectIndex == 1) {
            UITableView *tableView = [_scrollView viewWithTag:2000];
            _dataSource.sourceType = CCDebugDataSourceTypeFluency;
            tableView.scrollEnabled = YES;
            [tableView reloadData];
        } else if (selectIndex == 2) {
            UITableView *tableView = [_scrollView viewWithTag:3000];
            _dataSource.sourceType = CCDebugDataSourceTypeLog;
            tableView.scrollEnabled = YES;
            [tableView reloadData];
        } else if (selectIndex == 3) {
            UITableView *tableView = [_scrollView viewWithTag:4000];
            _dataSource.sourceType = CCDebugDataSourceTypeOperate;
            tableView.scrollEnabled = YES;
            [tableView reloadData];
        }
    }
}

#pragma mark -
#pragma mark :. UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    CCDebugContentViewController *viewController = [[CCDebugContentViewController alloc] init];
    viewController.title = [NSString stringWithFormat:@"%@日志", self.navigationItem.title];
    viewController.hidesBottomBarWhenPushed = YES;
    viewController.dataArr = self.dataSource.dataArr;
    viewController.selectedIndex = indexPath.row;
    [self pushCCNewViewController:viewController];
}

#pragma mark -
#pragma mark :. UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([scrollView isEqual:self.scrollView]) {
        CGFloat x = scrollView.contentOffset.x;
        NSInteger selectIndex = x / scrollView.frame.size.width;
        [self reloadData:selectIndex];
    }
}


#pragma mark -
#pragma mark :. getter/setter

- (UITableView *)createTableView:(CGFloat)x
{
    UITableView *logTableView = [[UITableView alloc] initWithFrame:CGRectMake(x, 0, _scrollView.frame.size.width, _scrollView.frame.size.height - 114) style:UITableViewStylePlain];
    logTableView.backgroundColor = [UIColor clearColor];
    logTableView.delegate = self;
    logTableView.dataSource = self.dataSource;
    logTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

    if (@available(iOS 11.0, *)) {
        logTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }

    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.backgroundColor = [UIColor clearColor];
    [logTableView setTableFooterView:v];

    return logTableView;
}

@end
