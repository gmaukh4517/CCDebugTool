

//
//  CookiesViewController.m
//  CCDebugTool
//
//  Created by CC on 2017/11/21.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCCookiesViewController.h"
#import <Foundation/Foundation.h>
#import "CCCookiesTableViewCell.h"
#import "CCCookieDetailViewController.h"

@interface CCCookiesViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *cookieTableView;

@property (nonatomic, strong) NSArray *dataArr;

@end

@implementation CCCookiesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self initNavigation];
    [self initControl];
    [self initLoadData];
}

- (void)initNavigation
{
    self.navigationItem.title = @"Cookies";
}

- (void)initControl
{
    [self.view addSubview:self.cookieTableView];
}

- (void)initLoadData
{
    NSSortDescriptor *nameSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    self.dataArr = [[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies sortedArrayUsingDescriptors:@[ nameSortDescriptor ]];
}

#pragma mark -
#pragma mark :. event handle

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
    CCCookiesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CCCookiesTableViewCellIdentifer"];
    [cell cc_cellWillDisplayWithModel:_dataArr[ indexPath.row ]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    CCCookieDetailViewController *viewController = [CCCookieDetailViewController new];
    viewController.cookie = [self.dataArr objectAtIndex:indexPath.row];
    viewController.hidesBottomBarWhenPushed = YES;
    [self pushCCNewViewController:viewController];
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

- (UITableView *)cookieTableView
{
    if (!_cookieTableView) {
        CGRect TableViewFrame = self.view.bounds;
        TableViewFrame.size.height = self.view.bounds.size.height - 64;

        UITableView *tooTableView = [[UITableView alloc] initWithFrame:TableViewFrame style:UITableViewStylePlain];
        tooTableView.backgroundColor = [UIColor clearColor];
        tooTableView.delegate = self;
        tooTableView.dataSource = self;
        tooTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        tooTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [tooTableView registerClass:[CCCookiesTableViewCell class] forCellReuseIdentifier:@"CCCookiesTableViewCellIdentifer"];
        [self.view addSubview:_cookieTableView = tooTableView];

        if (@available(iOS 11.0, *))
            tooTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor clearColor];
        [tooTableView setTableFooterView:v];
    }
    return _cookieTableView;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
