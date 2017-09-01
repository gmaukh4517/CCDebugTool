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
#import "CCDebugEnterLOGHelper.h"
#import "CCDebugTool.h"

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

- (void)initNavigation
{
    _itemTitle = @[ @"Crash", @"Caton", @"LOG" ];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:_itemTitle];
    segmentedControl.selectedSegmentIndex = 0;
    segmentedControl.clipsToBounds = YES;
    segmentedControl.tintColor = [UIColor whiteColor];
    segmentedControl.frame = CGRectMake(0, 0, 200, 30);
    segmentedControl.momentary = NO;
    [segmentedControl addTarget:self action:@selector(didSegmentedControl:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = segmentedControl;
    self.navigationItem.title = [_itemTitle objectAtIndex:0];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(dismissViewController)];
    self.currentIndex = -1;
    [self reloadData:0];
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
    scrollview.showsVerticalScrollIndicator = NO;
    scrollview.bounces = NO;
    scrollview.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    scrollview.delegate = self;
    scrollview.contentSize = CGSizeMake(scrollview.frame.size.width * 3, 0);
    [self.view addSubview:_scrollView = scrollview];
    
    UITableView *crashTableView = [self createTableView:0];
    crashTableView.tag = 1000;
    [scrollview addSubview:crashTableView];
    
    UITableView *cationTableView = [self createTableView:self.view.frame.size.width];
    cationTableView.tag = 2000;
    [scrollview addSubview:cationTableView];
    
    UITextView *logTextView = [[UITextView alloc] initWithFrame:CGRectMake(self.view.frame.size.width * 2, 0, self.view.frame.size.width, self.view.frame.size.height - 114)];
    [logTextView setEditable:NO];
    logTextView.tag = 3000;
    [scrollview addSubview:logTextView];
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
            [self refreshLogs];
        }
    }
}

- (void)refreshLogs
{
    __weak UITextView *weakTxt = [_scrollView viewWithTag:3000];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *arr = [CCDebugEnterLOGHelper logs:[CCDebugTool manager].maxLogsCount];
        if (arr.count > 0) {
            NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
            for (CCDebugLogModel *model in arr) {
                NSString *date = [CCDebugLogModel stringFormatFromDate:model.date];
                NSMutableAttributedString *att = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@：", date]];
                [att addAttribute:NSForegroundColorAttributeName value:[CCDebugTool manager].mainColor range:NSMakeRange(0, att.string.length)];
                
                NSMutableAttributedString *att2 = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n\n", model.messageText]];
                [att2 addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, att2.string.length)];
                
                [string appendAttributedString:att];
                [string appendAttributedString:att2];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                weakTxt.attributedText = string;
            });
        }
    });
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
    [self.navigationController pushViewController:viewController animated:YES];
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
    
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.backgroundColor = [UIColor clearColor];
    [logTableView setTableFooterView:v];
    
    return logTableView;
}

@end
