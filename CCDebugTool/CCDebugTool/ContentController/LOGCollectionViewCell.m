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

@interface LOGCollectionViewCell () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *logTableView;

@property (nonatomic, strong) NSArray *dataArr;

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
    [self.contentView addSubview:self.logTableView];
}

- (void)cc_cellWillDisplayWithModel:(id)cModel indexPath:(NSIndexPath *)cIndexPath
{
    self.dataArr = cModel;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.logTableView.frame = self.contentView.bounds;
}

#pragma mark - UITableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contentStr = [self.dataArr objectAtIndex:indexPath.row];

    NSDictionary<NSString *, id> *attributes = @{ NSFontAttributeName : [UIFont fontWithName:@"Helvetica-Bold" size:12] };
    NSAttributedString *attributedLogText = [[NSAttributedString alloc] initWithString:contentStr attributes:attributes];

    UIEdgeInsets insets = kCCLogMessageCellInsets;
    CGFloat availableWidth = tableView.bounds.size.width - insets.left - insets.right;
    CGSize labelSize = [attributedLogText boundingRectWithSize:CGSizeMake(availableWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    return ceil(labelSize.height + insets.top + insets.bottom)+1;
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

    ((LOGTableViewCell *)cell).contentStr = [self.dataArr objectAtIndex:indexPath.row];

    NSInteger totalRows = [tableView numberOfRowsInSection:indexPath.section];
    if ((totalRows - indexPath.row) % 2 == 0) {
        cell.backgroundColor = [UIColor colorWithHue:2.0 / 3.0 saturation:0.02 brightness:0.95 alpha:1];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
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
