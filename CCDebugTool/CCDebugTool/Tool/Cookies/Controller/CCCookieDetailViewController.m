//
//  CookieDetailViewController.m
//  CCDebugTool
//
//  Created by CC on 2017/11/21.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCCookieDetailViewController.h"
#import "CCDebugTool.h"
#import "CCDebugContentViewController.h"
#import "CCCookieManager.h"

@interface CCCookieDetailViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *detailTableView;

@property (nonatomic, strong) NSArray *dataArr;

@end

@implementation CCCookieDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"详情";
    [self initControl];
    [self initLoadData];
}

- (void)initControl
{
    [self.view addSubview:self.detailTableView];

    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.backgroundColor = [UIColor clearColor];
    [self.detailTableView setTableFooterView:v];
}

- (void)initLoadData
{
    _dataArr = [CCCookieManager cookiesProperties:self.cookie];
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
    static NSString *identifer = @"httpDetailIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifer];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = [CCDebugTool manager].mainColor;
    }

    cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
//    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *item = [self.dataArr objectAtIndex:indexPath.row];

    NSString *key = [item objectForKey:@"propertyType"];
    NSString *value = [item objectForKey:@"propertyValue"];

    CCDebugContentViewController *vc = [[CCDebugContentViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    if ([key isEqualToString:@"NSDictionary *"] || [key isEqualToString:@"NSArray *"] ||
        [key isEqualToString:@"NSMutableDictionary *"] || [key isEqualToString:@"NSMutableArray *"] ||
        [[item objectForKey:@"propertyName"] isEqualToString:@"value"]) {
        vc.content = value;
        vc.title = [item objectForKey:@"propertyName"];
    } else {
        return;
    }

    [self.navigationController pushViewController:vc animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self.dataArr objectAtIndex:indexPath.row];
    cell.textLabel.text = [item objectForKey:@"title"];
    cell.detailTextLabel.text = [item objectForKey:@"value"];

    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([[item objectForKey:@"propertyType"] isEqualToString:@"NSDictionary *"] || [[item objectForKey:@"propertyType"] isEqualToString:@"NSArray *"] ||
        [[item objectForKey:@"propertyType"] isEqualToString:@"NSMutableDictionary *"] || [[item objectForKey:@"propertyType"] isEqualToString:@"NSMutableArray *"] ||
        [[item objectForKey:@"propertyName"] isEqualToString:@"value"])
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

#pragma mark -
#pragma mark :. getter/setter

- (UITableView *)detailTableView
{
    if (!_detailTableView) {
        CGRect TableViewFrame = self.view.bounds;
        TableViewFrame.size.height = self.view.bounds.size.height;

        UITableView *tooTableView = [[UITableView alloc] initWithFrame:TableViewFrame style:UITableViewStylePlain];
        tooTableView.backgroundColor = [UIColor clearColor];
        tooTableView.delegate = self;
        tooTableView.dataSource = self;
        tooTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        tooTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        //        [tooTableView registerClass:[CCCookiesTableViewCell class] forCellReuseIdentifier:@"CCCookiesTableViewCellIdentifer"];
        [self.view addSubview:_detailTableView = tooTableView];

        if (@available(iOS 11.0, *))
            tooTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor clearColor];
        [tooTableView setTableFooterView:v];
    }
    return _detailTableView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
