//
//  CCDebugHttpDetailViewController.m
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

#import "CCDebugHttpDetailViewController.h"
#import "CCDebugContentViewController.h"
#import "CCDebugTool.h"

#define detailTitles @[ @"Request Url", @"Header Fields", @"Method", @"Status Code", @"Mime Type", @"Start Time", @"Total Duration", @"Request Body", @"Response Body" ]

@interface CCDebugHttpDetailViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *httpDetailtableView;
@property (nonatomic, strong) NSArray *dataArr;

@end

@implementation CCDebugHttpDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = self.transaction.url.host;
    [self initControl];
    [self initLoadData];
}

- (void)initControl
{
    self.httpDetailtableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.httpDetailtableView.backgroundColor = [UIColor clearColor];
    self.httpDetailtableView.delegate = self;
    self.httpDetailtableView.dataSource = self;
    self.httpDetailtableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.httpDetailtableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.httpDetailtableView];

    if (@available(iOS 11.0, *)) {
        self.httpDetailtableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }

    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.backgroundColor = [UIColor clearColor];
    [self.httpDetailtableView setTableFooterView:v];
}

- (void)initLoadData
{
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:@{ @"Request Url" : self.transaction.url.absoluteString }];
    [array addObject:@{ @"CachePolicy" : self.transaction.requestCachePolicy }];
    [array addObject:@{ @"Method" : self.transaction.method }];
    [array addObject:@{ @"Status Code" : self.transaction.statusCode ?: @"" }];
    [array addObject:@{ @"Mime Type" : self.transaction.mineType ?: @"" }];
    [array addObject:@{ @"Start Time" : self.transaction.showStartTime }];
    [array addObject:@{ @"Total Duration" : self.transaction.showTotalDuration }];

    NSString *total = [NSByteCountFormatter stringFromByteCount:self.transaction.requestDataTrafficValue + self.transaction.responseDataTrafficValue countStyle:NSByteCountFormatterCountStyleFile];
    NSString *request = [NSByteCountFormatter stringFromByteCount:self.transaction.requestDataTrafficValue countStyle:NSByteCountFormatterCountStyleFile];
    NSString *response = [NSByteCountFormatter stringFromByteCount:self.transaction.responseDataTrafficValue countStyle:NSByteCountFormatterCountStyleFile];

    [array addObject:@{ @"Data Traffic" : [NSString stringWithFormat:@"%@ (%@↑ / %@↓)", total, request, response] }];

    NSString *requestHeader = @"Empty";
    if (self.transaction.requestAllHeaderFields)
        requestHeader = [NSString stringWithFormat:@"Header Object"];
    [array addObject:@{ @"Request Header" : requestHeader }];
    NSString *value;
    if (self.transaction.requestDataSize > 0)
        value = [NSString stringWithFormat:@"( %@ ) Tap to view", [NSByteCountFormatter stringFromByteCount:self.transaction.requestDataSize countStyle:NSByteCountFormatterCountStyleBinary]];
    else
        value = @"Empty";
    [array addObject:@{ @"Request Body" : value }];

    NSString *responseHeader = @"Empty";
    if (self.transaction.responseAllHeaderFields)
        responseHeader = [NSString stringWithFormat:@"Header Object"];
    [array addObject:@{ @"Response Header" : responseHeader }];

    if (self.transaction.responseData.length > 0)
        value = [NSString stringWithFormat:@"( %@ ) Tap to view", [NSByteCountFormatter stringFromByteCount:self.transaction.responseData.length countStyle:NSByteCountFormatterCountStyleBinary]];
    else
        value = @"Empty";
    [array addObject:@{ @"Response Body" : value }];

    _dataArr = array;
}

#pragma mark - UITableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArr.count;
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
    static NSString *identifer = @"httpDetailIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifer];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = [CCDebugTool manager].mainColor;
    }

    cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:19];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [[self.dataArr objectAtIndex:indexPath.row] allKeys].lastObject;
    cell.textLabel.text = key;
    NSString *value = [[self.dataArr objectAtIndex:indexPath.row] objectForKey:key];
    cell.detailTextLabel.text = value;

    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([key isEqualToString:@"Request Url"] ||
        [key isEqualToString:@"Header Fields"] ||
        [key isEqualToString:@"Request Header"] ||
        [key isEqualToString:@"Response Header"] ||
        (([key isEqualToString:@"Request Body"] || [key isEqualToString:@"Response Body"]) && ![value isEqualToString:@"Empty"]))
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

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

    NSString *key = [[self.dataArr objectAtIndex:indexPath.row] allKeys].lastObject;
    NSString *value = [[self.dataArr objectAtIndex:indexPath.row] objectForKey:key];

    CCDebugContentViewController *viewController = [[CCDebugContentViewController alloc] init];

    viewController.hidesBottomBarWhenPushed = YES;
    if ([key isEqualToString:@"Request Url"]) {
        viewController.url = self.transaction.url.absoluteString;
    } else if ([key isEqualToString:@"Request Header"]) {
        viewController.title = @"请求Header";
        viewController.content = self.transaction.showRequestAllHeaderFields;
    } else if ([key isEqualToString:@"Response Header"]) {
        viewController.title = @"返回Header";
        viewController.content = self.transaction.showResponseAllHeaderFields;
    } else if ([key isEqualToString:@"Request Body"] && ![value isEqualToString:@"Empty"]) {
        viewController.content = self.transaction.requestBody;
        viewController.title = @"请求数据";
    } else if ([key isEqualToString:@"Response Body"] && ![value isEqualToString:@"Empty"]) {
        viewController.content = self.transaction.responseBody;
        if (self.transaction.isImage) {
            viewController.content = nil;
            viewController.data = self.transaction.responseData;
        }
        viewController.title = @"返回数据";
    } else {
        return;
    }

    [self pushCCNewViewController:viewController];
}

@end
