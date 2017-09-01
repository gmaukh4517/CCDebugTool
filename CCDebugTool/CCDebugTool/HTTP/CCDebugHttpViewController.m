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
#import "CCDebugHttpDataSource.h"
#import "CCDebugHttpDetailViewController.h"
#import "CCDebugTool.h"

@interface CCDebugHttpViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) UITableView *httpViewTableView;
@property (nonatomic, strong) NSArray *dataArray;

@end

@implementation CCDebugHttpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initNavigation];
    [self initControl];
    [self initLoadData];
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
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(dismissViewController)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStyleDone target:self action:@selector(clearAction)];
}

- (void)dismissViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)initControl
{
    UITableView *httpViewTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    httpViewTableView.backgroundColor = [UIColor clearColor];
    httpViewTableView.delegate = self;
    httpViewTableView.dataSource = self;
    httpViewTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    httpViewTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.httpViewTableView = httpViewTableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initLoadData) name:kCCNotifyKeyReloadHttp object:nil];
}

- (void)clearAction
{
    [[CCDebugHttpDataSource manager] clear];
    self.dataArray = nil;
    [self.httpViewTableView reloadData];
}

- (void)initLoadData
{
    self.dataArray = [[[CCDebugHttpDataSource manager] httpArray] copy];
    __block double flowCount = 0;
    [self.dataArray enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        flowCount += [obj expectedContentLength];
    }];
    
    if (!flowCount) {
        flowCount = 0.0;
    }
    
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
    
    [self.httpViewTableView reloadData];
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

#pragma mark - UITableView Delegate
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
    static NSString *identifer = @"httpcell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifer];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.textColor = [CCDebugTool manager].mainColor;
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:19];
    }
    
    CCDebugHttpModel *model = [self.dataArray objectAtIndex:indexPath.row];
    
    cell.textLabel.text = model.url.host;
    
    NSString *detailText = [NSString stringWithFormat:@"%@ %@ %@", model.method, model.statusCode, model.totalDuration];
    
    NSMutableAttributedString *detailAtt = [[NSMutableAttributedString alloc] initWithString:detailText];
    [detailAtt addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, detailText.length)];
    
    if ([model.statusCode integerValue] != 200) {
        [detailAtt addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(model.method.length + 1, model.statusCode.length)];
    }
    
    cell.detailTextLabel.attributedText = detailAtt;
    
    return cell;
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
