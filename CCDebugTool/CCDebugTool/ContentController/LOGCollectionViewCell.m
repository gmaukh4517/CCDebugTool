//
//  LOGCollectionViewCell.m
//  CCDebugTool
//
//  Created by CC on 2019/9/27.
//  Copyright © 2019 CC. All rights reserved.
//

#import "LOGCollectionViewCell.h"

static const UIEdgeInsets kCCLogMessageCellInsets = {10.0, 20.0, 10.0, 20.0};

@interface LOGTableViewCell : UITableViewCell

@property (nonatomic, weak) UILabel *logMessageLabel;

@property (nonatomic, copy) NSAttributedString *logMessageAttributedText;

@property (nonatomic, copy) NSString *contentStr;

@end

@interface LOGCollectionViewCell () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (nonatomic, strong) UITableView *logTableView;

@property (nonatomic, strong) NSArray *dataArr;

@property (nonatomic, strong) NSMutableArray *searchDataArray;
@property (nonatomic, copy) NSString *searchText;

@end

@implementation LOGCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initControl];
    }
    return self;
}

- (void)initControl
{
    self.clipsToBounds = YES;
    self.searchDataArray = [NSMutableArray array];

    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
    tableHeaderView.backgroundColor = [UIColor whiteColor];

    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, tableHeaderView.frame.size.width, 44)];
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.delegate = self;
    [tableHeaderView addSubview:searchBar];

    self.logTableView.tableHeaderView = tableHeaderView;

    [self.contentView addSubview:self.logTableView];
}

- (void)cc_cellWillDisplayWithModel:(id)cModel indexPath:(NSIndexPath *)cIndexPath
{
    self.dataArr = cModel;

    dispatch_after(dispatch_walltime(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^() {
        NSInteger s = [self.logTableView numberOfSections];            //有多少组
        if (s < 1) return;                                             //无数据时不执行 要不会crash
        NSInteger r = [self.logTableView numberOfRowsInSection:s - 1]; //最后一组有多少行
        if (r < 1) return;
        NSIndexPath *ip = [NSIndexPath indexPathForRow:r - 1 inSection:s - 1];                                      //取最后一行数据
        [self.logTableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:NO]; //滚动到最后一行
    });
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.logTableView.frame = self.contentView.bounds;
}

#pragma mark - UITableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = self.dataArr.count;
    if (self.searchText.length)
        count = self.searchDataArray.count;

    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contentStr = [self.dataArr objectAtIndex:indexPath.row];
    if (self.searchText.length)
        contentStr = [self.searchDataArray objectAtIndex:indexPath.row];

    NSDictionary<NSString *, id> *attributes = @{ NSFontAttributeName : [UIFont fontWithName:@"Helvetica-Bold" size:12] };
    NSAttributedString *attributedLogText = [[NSAttributedString alloc] initWithString:contentStr attributes:attributes];

    UIEdgeInsets insets = kCCLogMessageCellInsets;
    CGFloat availableWidth = tableView.bounds.size.width - insets.left - insets.right;
    CGSize labelSize = [attributedLogText boundingRectWithSize:CGSizeMake(availableWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    return ceil(labelSize.height + insets.top + insets.bottom) + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifer = @"LOGTableViewCellIdentifer";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell)
        cell = [[LOGTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifer];

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

    NSString *contentStr = [self.dataArr objectAtIndex:indexPath.row];
    if (self.searchText.length)
        contentStr = [self.searchDataArray objectAtIndex:indexPath.row];
    ((LOGTableViewCell *)cell).contentStr = contentStr;

    NSInteger totalRows = [tableView numberOfRowsInSection:indexPath.section];
    if ((totalRows - indexPath.row) % 2 == 0) {
        cell.backgroundColor = [UIColor colorWithHue:2.0 / 3.0 saturation:0.02 brightness:0.95 alpha:0.65];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    UISearchBar *searchBar = (UISearchBar *)self.logTableView.tableHeaderView;
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
        for (NSString *content in self.dataArr) {
            if ([content.lowercaseString containsString:searchText.lowercaseString])
                [self.searchDataArray addObject:content];
        }
    }

    [self.logTableView reloadData];
}

#pragma mark -
#pragma mark :. getter/setter

- (UITableView *)logTableView
{
    if (!_logTableView) {
        UITableView *logTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        logTableView.backgroundColor = [UIColor clearColor];
        logTableView.delegate = self;
        logTableView.dataSource = self;
        logTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        logTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        if (@available(iOS 11.0, *))
            logTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor clearColor];
        [logTableView setTableFooterView:v];
        _logTableView = logTableView;
    }
    return _logTableView;
}


@end

@implementation LOGTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        UILabel *logMessageLabel = [UILabel new];
        logMessageLabel = [UILabel new];
        logMessageLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
        logMessageLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
        logMessageLabel.numberOfLines = 0;
        self.separatorInset = UIEdgeInsetsZero;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.contentView addSubview:_logMessageLabel = logMessageLabel];
    }
    return self;
}

- (void)setContentStr:(NSString *)contentStr
{
    if (![_contentStr isEqualToString:contentStr]) {
        _contentStr = contentStr;
        self.logMessageAttributedText = nil;
        [self setNeedsLayout];
    }
}

- (NSAttributedString *)logMessageAttributedText
{
    if (!_logMessageAttributedText) {
        NSDictionary<NSString *, id> *attributes = @{ NSFontAttributeName : [UIFont fontWithName:@"Helvetica-Bold" size:12] };
        _logMessageAttributedText = [[NSAttributedString alloc] initWithString:self.contentStr attributes:attributes];
    }
    return _logMessageAttributedText;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.logMessageLabel.attributedText = self.logMessageAttributedText;
    self.logMessageLabel.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, kCCLogMessageCellInsets);
}

@end
