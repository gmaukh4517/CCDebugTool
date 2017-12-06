//
//  LeftDatabaseView.m
//  CCDebugTool
//
//  Created by CC on 2017/12/6.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "LeftDatabaseView.h"
#import "DatabaseTableViewCell.h"
#import "CCDebugTool.h"

static NSString *const kDatabaseTableViewCellIdentifer = @"kDatabaseTableViewCellIdentifer";

@interface LeftDatabaseView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *databaseTableView;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray *databaseArr;
@property (nonatomic, strong) NSArray *tableArr;

@end

@implementation LeftDatabaseView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initialization];
    }
    return self;
}

- (void)initialization
{
    UILabel *databaseLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 30)];
    databaseLabel.backgroundColor = [CCDebugTool manager].mainColor; //[UIColor colorWithRed:0.819 green:0.909 blue:0.956 alpha:1];
    databaseLabel.font = [UIFont systemFontOfSize:15];
    databaseLabel.text = @"  Databases";
    [self addSubview:databaseLabel];

    self.databaseTableView.frame = CGRectMake(0, databaseLabel.frame.origin.y + databaseLabel.frame.size.height, self.frame.size.width, self.bounds.size.height / 4);
    [self addSubview:self.databaseTableView];

    CGFloat y = self.databaseTableView.frame.origin.y + self.databaseTableView.frame.size.height;

    UILabel *tableLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, self.bounds.size.width, 30)];
    tableLabel.backgroundColor = databaseLabel.backgroundColor;
    tableLabel.font = [UIFont systemFontOfSize:15];
    tableLabel.text = @"  Tables";
    [self addSubview:tableLabel];

    y += tableLabel.frame.size.height;

    self.tableView.frame = CGRectMake(0, y, self.frame.size.width, self.frame.size.height - y);
    [self addSubview:self.tableView];

    UIView *verticalLine = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width - 1, 0, 1, self.frame.size.height)];
    verticalLine.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1];
    [self addSubview:verticalLine];
}

- (void)fillDatabase:(NSArray *)arr
{
    _databaseArr = arr;
    [self.databaseTableView reloadData];
}

- (void)fillTable:(NSArray *)arr
{
    _tableArr = arr;
    [self.tableView reloadData];
}

#pragma mark - UITableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if (tableView == self.databaseTableView) {
        count = self.databaseArr.count;
    } else if (tableView == self.tableView) {
        count = self.tableArr.count;
    }
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DatabaseTableViewCell *cell = (DatabaseTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kDatabaseTableViewCellIdentifer];

    NSString *content;
    if (tableView == self.databaseTableView) {
        content = [[self.databaseArr objectAtIndex:indexPath.row] objectForKey:@"name"];
    } else if (tableView == self.tableView) {
        content = [self.tableArr objectAtIndex:indexPath.row];
    }

    [cell cc_cellWillDisplayWithModel:content];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.databaseTableView) {
        NSString *path = [[self.databaseArr objectAtIndex:indexPath.row] objectForKey:@"path"];
        if ([self.delegate respondsToSelector:@selector(didDatabaseClick:)]) {
            [self.delegate didDatabaseClick:path];
        }

    } else if (tableView == self.tableView) {
        if ([self.delegate respondsToSelector:@selector(didTableClick:)]) {
            [self.delegate didTableClick:[self.tableArr objectAtIndex:indexPath.row]];
        }
    }
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

- (UITableView *)databaseTableView
{
    if (!_databaseTableView) {
        _databaseTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _databaseTableView.backgroundColor = [UIColor clearColor];
        _databaseTableView.delegate = self;
        _databaseTableView.dataSource = self;
        _databaseTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [_databaseTableView registerClass:[DatabaseTableViewCell class] forCellReuseIdentifier:kDatabaseTableViewCellIdentifer];

        if (@available(iOS 11.0, *))
            _databaseTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor clearColor];
        [_databaseTableView setTableFooterView:v];
    }
    return _databaseTableView;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [_tableView registerClass:[DatabaseTableViewCell class] forCellReuseIdentifier:kDatabaseTableViewCellIdentifer];

        if (@available(iOS 11.0, *))
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor clearColor];
        [_tableView setTableFooterView:v];
    }
    return _tableView;
}

@end
