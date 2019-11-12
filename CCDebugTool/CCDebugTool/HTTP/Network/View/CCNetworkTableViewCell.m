//
//  CCHTTPTableViewCell.m
//  CCDebugTool
//
//  Created by CC on 2017/11/9.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCNetworkTableViewCell.h"
#import "CCDebugTool.h"

@interface CCNetworkTableViewCell ()

@property (nonatomic, weak) UILabel *pathLabel;

@end

@implementation CCNetworkTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        self.imageView.layer.borderColor = UIColor.blackColor.CGColor;
        self.imageView.layer.borderWidth = 0.5;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;

        self.textLabel.textColor = [CCDebugTool manager].mainColor;
        self.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];

        UILabel *pathLabel = [UILabel new];
        pathLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
        pathLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
        [self.contentView addSubview:_pathLabel = pathLabel];

        self.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10];
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    }
    return self;
}

- (void)setTransaction:(CCNetworkTransaction *)transaction
{
    if (_transaction != transaction) {
        _transaction = transaction;
        [self setNeedsLayout];
    }
}

- (NSString *)textLabelText
{
    NSString *title = [NSString stringWithFormat:@"App - %@", self.transaction.url.host];
    if ([self.transaction.requestMechanism hasSuffix:@"WKCustomProtocolLoader)"])
        title = [NSString stringWithFormat:@"Web - %@", self.transaction.url.host];

    return title;
}

- (NSString *)pathLabelText
{
    NSURL *url = self.transaction.request.URL;
    NSString *name = [url lastPathComponent];
    if (name.length == 0) {
        name = @"/";
    }
    NSString *query = [url query];
    if (query)
        name = [name stringByAppendingFormat:@"?%@", query];

    return name;
}

- (NSAttributedString *)transactionDetailsLabelText
{
    NSMutableArray<NSString *> *detailComponents = [NSMutableArray array];
    NSString *timestamp = [[self class] timestampStringFromRequestDate:self.transaction.startTime];
    if (timestamp.length > 0)
        [detailComponents addObject:timestamp];

    [detailComponents addObject:self.transaction.method];

    if (self.transaction.transactionState == CCNetworkTransactionStateFinished || self.transaction.transactionState == CCNetworkTransactionStateFailed) {
        [detailComponents addObject:self.transaction.statusCode];
        if (self.transaction.expectedContentLength > 0) {
            NSString *responseSize = [NSByteCountFormatter stringFromByteCount:self.transaction.expectedContentLength countStyle:NSByteCountFormatterCountStyleBinary];
            [detailComponents addObject:responseSize];
        }

        NSString *duration = [NSString stringWithFormat:@"%@ (%@)", self.transaction.showTotalDuration, self.transaction.showLatency];
        [detailComponents addObject:duration];
    } else {
        NSString *state = [CCNetworkTransaction readableStringFromTransactionState:self.transaction.transactionState];
        [detailComponents addObject:state];
    }

    NSString *transactionDetailsLabelText = [detailComponents componentsJoinedByString:@" ・ "];
    NSMutableAttributedString *detailAtt = [[NSMutableAttributedString alloc] initWithString:transactionDetailsLabelText];
    [detailAtt addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, transactionDetailsLabelText.length)];
    if (self.transaction.statusCode && [self.transaction.statusCode integerValue] != 200)
        [detailAtt addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:[transactionDetailsLabelText rangeOfString:self.transaction.statusCode]];

    return detailAtt;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    const CGFloat kVerticalPadding = 8.0;
    const CGFloat kLeftPadding = 10.0;
    const CGFloat kImageDimension = 32.0;

    CGFloat thumbnailOriginY = round((self.contentView.bounds.size.height - kImageDimension) / 2.0);
    self.imageView.frame = CGRectMake(kLeftPadding, thumbnailOriginY, kImageDimension, kImageDimension);
    self.imageView.image = self.transaction.responseThumbnail ?: [UIImage new];

    CGFloat textOriginX = CGRectGetMaxX(self.imageView.frame) + kLeftPadding;
    CGFloat availableTextWidth = self.contentView.bounds.size.width - textOriginX;

    self.textLabel.text = [self textLabelText];
    CGSize nameLabelPreferredSize = [self.textLabel sizeThatFits:CGSizeMake(availableTextWidth, CGFLOAT_MAX)];
    self.textLabel.frame = CGRectMake(textOriginX, kVerticalPadding, availableTextWidth, nameLabelPreferredSize.height);

    self.pathLabel.text = [self pathLabelText];
    CGSize pathLabelPreferredSize = [self.pathLabel sizeThatFits:CGSizeMake(availableTextWidth, CGFLOAT_MAX)];
    CGFloat pathLabelOriginY = ceil((self.contentView.bounds.size.height - pathLabelPreferredSize.height) / 2.0);
    self.pathLabel.frame = CGRectMake(textOriginX, pathLabelOriginY, availableTextWidth, pathLabelPreferredSize.height);

    self.detailTextLabel.attributedText = [self transactionDetailsLabelText];
    CGSize transactionLabelPreferredSize = [self.detailTextLabel sizeThatFits:CGSizeMake(availableTextWidth, CGFLOAT_MAX)];
    CGFloat transactionDetailsOriginX = textOriginX;
    CGFloat transactionDetailsLabelOriginY = CGRectGetMaxY(self.contentView.bounds) - kVerticalPadding - transactionLabelPreferredSize.height;
    CGFloat transactionDetailsLabelWidth = self.contentView.bounds.size.width - transactionDetailsOriginX;
    self.detailTextLabel.frame = CGRectMake(transactionDetailsOriginX, transactionDetailsLabelOriginY, transactionDetailsLabelWidth, transactionLabelPreferredSize.height);
}

+ (NSString *)timestampStringFromRequestDate:(NSDate *)date
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"HH:mm:ss";
    });
    return [dateFormatter stringFromDate:date];
}

@end
