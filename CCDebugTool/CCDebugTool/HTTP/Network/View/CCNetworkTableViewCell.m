//
//  CCHTTPTableViewCell.m
//  CCDebugTool
//
//  Created by CC on 2017/11/9.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCNetworkTableViewCell.h"
#import "CCDebugTool.h"

@implementation CCNetworkTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        self.imageView.layer.borderColor = UIColor.blackColor.CGColor;
        self.imageView.layer.borderWidth = 0.5;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;

        self.textLabel.textColor = [CCDebugTool manager].mainColor;
        self.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:19];

        self.detailTextLabel.font =[UIFont fontWithName:@"HelveticaNeue" size:10];
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

- (void)cc_cellWillDisplayWithModel
{
    self.imageView.image = self.transaction.responseThumbnail?:[UIImage new];
    self.textLabel.text = self.transaction.url.host;

    NSString *transactionDetailsLabelText = [self transactionDetailsLabelText];

    NSMutableAttributedString *detailAtt = [[NSMutableAttributedString alloc] initWithString:transactionDetailsLabelText];
    [detailAtt addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, transactionDetailsLabelText.length)];
    if (self.transaction.statusCode && [self.transaction.statusCode integerValue] != 200)
        [detailAtt addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:[transactionDetailsLabelText rangeOfString:self.transaction.statusCode]];
    self.detailTextLabel.attributedText = detailAtt;
}

- (NSString *)transactionDetailsLabelText
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

    return [detailComponents componentsJoinedByString:@" ・ "];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    const CGFloat kLeftPadding = 10.0;
    const CGFloat kImageDimension = 32.0;

    CGFloat thumbnailOriginY = round((self.contentView.bounds.size.height - kImageDimension) / 2.0);
    CGRect imageViewFrame = self.imageView.frame;
    imageViewFrame.origin.x = kLeftPadding;
    imageViewFrame.origin.y = thumbnailOriginY;
    imageViewFrame.size = CGSizeMake(kImageDimension, kImageDimension);
    self.imageView.frame = imageViewFrame;

    CGRect textLabelFrame = self.textLabel.frame;
    textLabelFrame.origin.x = imageViewFrame.origin.x + imageViewFrame.size.width + kLeftPadding;
    textLabelFrame.origin.y = 7;
    self.textLabel.frame = textLabelFrame;

    CGRect detailTextLabelFrame = self.detailTextLabel.frame;
    detailTextLabelFrame.origin.x = imageViewFrame.origin.x + imageViewFrame.size.width + kLeftPadding;
    detailTextLabelFrame.origin.y = textLabelFrame.origin.y + textLabelFrame.size.height + 5;
    detailTextLabelFrame.size.width = self.contentView.bounds.size.width - detailTextLabelFrame.origin.x - kLeftPadding;
    self.detailTextLabel.frame = detailTextLabelFrame;

    [self cc_cellWillDisplayWithModel];
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
