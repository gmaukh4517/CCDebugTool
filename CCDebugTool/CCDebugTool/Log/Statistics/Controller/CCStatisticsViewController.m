//
//  CCStatisticsViewController.m
//  CCDebugTool
//
//  Created by CC on 2019/11/19.
//  Copyright © 2019 CC. All rights reserved.
//

#import "CCStatisticsViewController.h"
#import "CCStatisticsTableViewCell.h"

#import "CCStatistics.h"

@interface CCStatisticsViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UITableView *statisticsTableView;

@property (nonatomic, strong) NSDictionary *dataDic;

@property (nonatomic, strong) NSMutableArray *searchDataArray;
@property (nonatomic, copy) NSString *searchText;

@end

@implementation CCStatisticsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"统计";
    self.view.backgroundColor = [UIColor whiteColor];
    [self initControl];
    [self initLoadData];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.statisticsTableView.frame = self.view.bounds;
}

- (void)initControl
{
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
    tableHeaderView.backgroundColor = [UIColor whiteColor];

    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, tableHeaderView.frame.size.width, 44)];
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.delegate = self;
    [tableHeaderView addSubview:searchBar];

    self.statisticsTableView.tableHeaderView = tableHeaderView;
    [self.view addSubview:self.statisticsTableView];
}

- (void)initLoadData
{
    self.dataDic = [[CCStatistics manager] obtainStatistics];
    self.searchDataArray = [NSMutableArray array];
}

#pragma mark -
#pragma mark :. UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = self.dataDic.allKeys.count;
    if (self.searchText.length)
        count = self.searchDataArray.count;

    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CCDebugLogCellIdentifier"];
    if (!cell)
        cell = [[CCStatisticsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CCDebugLogCellIdentifier"];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)])
        [cell setSeparatorInset:UIEdgeInsetsZero];
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)])
        [cell setPreservesSuperviewLayoutMargins:NO];
    if ([cell respondsToSelector:@selector(setLayoutMargins:)])
        [cell setLayoutMargins:UIEdgeInsetsZero];

    NSString *key = [self.dataDic.allKeys objectAtIndex:indexPath.row];
    if (self.searchText.length)
        key = [self.searchDataArray objectAtIndex:indexPath.row];

    [((CCStatisticsTableViewCell *)cell) cc_cellWillDisplayWithModel:[self.dataDic objectForKey:key] indexPath:indexPath];

    NSInteger totalRows = [tableView numberOfRowsInSection:indexPath.section];
    if ((totalRows - indexPath.row) % 2 == 0) {
        cell.backgroundColor = [UIColor colorWithHue:2.0 / 3.0 saturation:0.02 brightness:0.95 alpha:0.65];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    UISearchBar *searchBar = (UISearchBar *)self.statisticsTableView.tableHeaderView;
    [searchBar resignFirstResponder];
}

#pragma mark - UISearchBar Delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.searchText = searchText;
    [self.searchDataArray removeAllObjects];
    if (![searchText isEqualToString:@""]) {
        for (NSDictionary *item in self.dataDic.allValues) {
            NSString *key = [item objectForKey:@"key"];
            if ([key.lowercaseString containsString:searchText.lowercaseString])
                [self.searchDataArray addObject:[self.dataDic allKeysForObject:item].lastObject];
        }
    }

    [self.statisticsTableView reloadData];
}


#pragma mark -
#pragma mark :. getter/setter

- (UITableView *)statisticsTableView
{
    if (!_statisticsTableView) {
        UITableView *statisticsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        statisticsTableView.backgroundColor = [UIColor clearColor];
        statisticsTableView.delegate = self;
        statisticsTableView.dataSource = self;
        statisticsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        statisticsTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        if (@available(iOS 11.0, *))
            statisticsTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor clearColor];
        [statisticsTableView setTableFooterView:v];
        _statisticsTableView = statisticsTableView;
    }
    return _statisticsTableView;
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
