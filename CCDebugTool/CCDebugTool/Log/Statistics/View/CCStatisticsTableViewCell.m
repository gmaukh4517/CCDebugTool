//
//  CCStatisticsTableViewCell.m
//  CCDebugTool
//
//  Created by CC on 2019/11/19.
//  Copyright © 2019 CC. All rights reserved.
//

#import "CCStatisticsTableViewCell.h"
#import "CCDebugTool.h"

@interface CCStatisticsTableViewCell ()

@property (nonatomic, weak) UILabel *nameLabel;

@property (nonatomic, weak) UILabel *loadingCountLabel;

@property (nonatomic, weak) UILabel *lastLoadingTimeLabel;

@property (nonatomic, weak) UILabel *lastStayTimeLabel;

@property (nonatomic, weak) UILabel *averageLoaingTimeLabel;

@property (nonatomic, weak) UILabel *averageStayTimeLabel;

@end

@implementation CCStatisticsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self initControl];
    }
    return self;
}

- (void)initControl
{
    self.clipsToBounds = YES;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    UILabel *nameLabel = [UILabel new];
    nameLabel.textColor = [CCDebugTool manager].mainColor;
    nameLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    [self.contentView addSubview:_nameLabel = nameLabel];

    UILabel *loadingCountLabel = [UILabel new];
    loadingCountLabel.textAlignment = NSTextAlignmentCenter;
    loadingCountLabel.textColor = [UIColor lightGrayColor];
    loadingCountLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    [self.contentView addSubview:_loadingCountLabel = loadingCountLabel];

    UILabel *lastLoadingTimeLabel = [UILabel new];
    lastLoadingTimeLabel.textColor = [UIColor lightGrayColor];
    lastLoadingTimeLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    [self.contentView addSubview:_lastLoadingTimeLabel = lastLoadingTimeLabel];

    UILabel *lastStayTimeLabel = [UILabel new];
    lastStayTimeLabel.textColor = [UIColor lightGrayColor];
    lastStayTimeLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    [self.contentView addSubview:_lastStayTimeLabel = lastStayTimeLabel];

    UILabel *averageLoaingTimeLabel = [UILabel new];
    averageLoaingTimeLabel.textColor = [UIColor lightGrayColor];
    averageLoaingTimeLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    [self.contentView addSubview:_averageLoaingTimeLabel = averageLoaingTimeLabel];

    UILabel *averageStayTimeLabel = [UILabel new];
    averageStayTimeLabel.textColor = [UIColor lightGrayColor];
    averageStayTimeLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    [self.contentView addSubview:_averageStayTimeLabel = averageStayTimeLabel];
}

- (void)cc_cellWillDisplayWithModel:(id)cModel indexPath:(NSIndexPath *)cIndexPath
{
    NSDictionary *item = cModel;
    self.nameLabel.text = [item objectForKey:@"key"];

    NSInteger count = [[item objectForKey:@"enterCount"] integerValue];

    self.loadingCountLabel.text = [NSString stringWithFormat:@"( %zi )", count];
    
    self.lastLoadingTimeLabel.text = [NSString stringWithFormat:@"最近加载：%.3fs", [[item objectForKey:@"appearDuration"] doubleValue]];
    self.lastStayTimeLabel.text = [NSString stringWithFormat:@"最近停留：%.3fs", [[item objectForKey:@"statisticDuration"] doubleValue]];

    double average = ([[item objectForKey:@"appearDuration"] doubleValue] ?: [[item objectForKey:@"appearDuration"] doubleValue]) / count;
    self.averageLoaingTimeLabel.text = [NSString stringWithFormat:@"平均加载：%.3fs", average];

    average = ([[item objectForKey:@"totalTime"] doubleValue] ?: [[item objectForKey:@"totalTime"] doubleValue]) / count;
    self.averageStayTimeLabel.text = [NSString stringWithFormat:@"平均停留：%.3fs", average];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    const CGFloat kVerticalPadding = 8.0;
    const CGFloat kLeftPadding = 10.0;
    CGFloat width = self.contentView.bounds.size.width;

    self.nameLabel.frame = CGRectMake(kLeftPadding, kVerticalPadding, width - 40 - kLeftPadding * 2, 20);
    self.loadingCountLabel.frame = CGRectMake(self.nameLabel.frame.origin.x + self.nameLabel.frame.size.width, kVerticalPadding, 40, 20);

    width = (width - kVerticalPadding * 3) / 2;
    self.lastLoadingTimeLabel.frame = CGRectMake(kLeftPadding, CGRectGetMaxY(self.nameLabel.frame) + kVerticalPadding, width, 20);
    self.lastStayTimeLabel.frame = CGRectMake(width + kVerticalPadding * 2, CGRectGetMaxY(self.nameLabel.frame) + kVerticalPadding, width, 20);

    self.averageLoaingTimeLabel.frame = CGRectMake(kLeftPadding, CGRectGetMaxY(self.lastLoadingTimeLabel.frame) + kVerticalPadding, width, 20);
    self.averageStayTimeLabel.frame = CGRectMake(width + kVerticalPadding * 2, CGRectGetMaxY(self.lastLoadingTimeLabel.frame) + kVerticalPadding, width, 20);
}

@end
