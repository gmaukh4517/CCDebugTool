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
    self.title = @"详情";
    [self initControl];
    [self initLoadData];
}

- (void)initControl
{
    self.httpDetailtableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.httpDetailtableView.backgroundColor = [UIColor clearColor];
    self.httpDetailtableView.delegate = self;
    self.httpDetailtableView.dataSource = self;
    self.httpDetailtableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.httpDetailtableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.httpDetailtableView];
}

- (void)initLoadData
{
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:@{ @"Request Url" : self.detail.url.absoluteString }];
    [array addObject:@{ @"CachePolicy" : self.detail.requestCachePolicy }];
    [array addObject:@{ @"Method" : self.detail.method }];
    [array addObject:@{ @"Status Code" : self.detail.statusCode }];
    [array addObject:@{ @"Mime Type" : self.detail.mineType }];
    [array addObject:@{ @"Start Time" : self.detail.startTime }];
    [array addObject:@{ @"Total Duration" : self.detail.totalDuration }];
    
    [array addObject:@{ @"Request Header" : [NSString stringWithFormat:@"User-Agent : %@", [self.detail.requestAllHeaderFields objectForKey:@"User-Agent"]] }];
    NSString *value;
    if (self.detail.requestDataSize > 0)
        value = [self dataSize:self.detail.requestDataSize];
    else
        value = @"Empty";
    [array addObject:@{ @"Request Body" : value }];
    
    [array addObject:@{ @"Response Header" : [NSString stringWithFormat:@"Server : %@", [self.detail.responseAllHeaderFields objectForKey:@"Server"]] }];
    if (self.detail.responseData.length > 0)
        value = [self dataSize:self.detail.responseData.length];
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
}

#define KB (1024)
#define MB (KB * 1024)
#define GB (MB * 1024)
- (NSString *)dataSize:(NSInteger)n
{
    NSString *value;
    if (n < KB) {
        value = [NSString stringWithFormat:@"( %ziB ) Tap to view", n];
    } else if (n < MB) {
        value = [NSString stringWithFormat:@"( %.2fKB ) Tap to view", (float)n / (float)KB];
    } else if (n < GB) {
        value = [NSString stringWithFormat:@"( %.2fMB ) Tap to view", (float)n / (float)MB];
    } else {
        value = [NSString stringWithFormat:@"( %.2fG ) Tap to view", (float)n / (float)GB];
    }
    return value;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *key = [[self.dataArr objectAtIndex:indexPath.row] allKeys].lastObject;
    NSString *value = [[self.dataArr objectAtIndex:indexPath.row] objectForKey:key];
    
    CCDebugContentViewController *vc = [[CCDebugContentViewController alloc] init];
    
    vc.hidesBottomBarWhenPushed = YES;
    if ([key isEqualToString:@"Request Url"]) {
        vc.content = self.detail.url.absoluteString;
        vc.title = @"接口地址";
    } else if ([key isEqualToString:@"Request Header"]) {
        vc.title = @"请求Header";
        vc.content = [CCDebugHttpDataSource prettyJSONStringFromData:self.detail.requestAllHeaderFields];
    } else if ([key isEqualToString:@"Response Header"]) {
        vc.title = @"返回Header";
        vc.content = [CCDebugHttpDataSource prettyJSONStringFromData:self.detail.responseAllHeaderFields];
    } else if ([key isEqualToString:@"Request Body"] && ![value isEqualToString:@"Empty"]) {
        vc.content = self.detail.requestBody;
        vc.title = @"请求数据";
    } else if ([key isEqualToString:@"Response Body"] && ![value isEqualToString:@"Empty"]) {
        vc.content = self.detail.responseBody;
        if (self.detail.isImage) {
            vc.content = nil;
            vc.data = self.detail.responseData;
        }
        vc.title = @"返回数据";
    } else {
        return;
    }
    
    [self.navigationController pushViewController:vc animated:YES];
}

@end
