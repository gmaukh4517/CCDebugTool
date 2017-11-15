//
//  CCHTTPTableViewCell.m
//  CCDebugTool
//
//  Created by CC on 2017/11/9.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCHTTPTableViewCell.h"
#import "CCDebugTool.h"

@implementation CCHTTPTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.textLabel.textColor = [CCDebugTool manager].mainColor;
        self.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:19];
    }
    return self;
}

-(void)cc_cellWillDisplayWithModel:(CCNetworkTransaction *)cModel
{
    _transaction = cModel;
    self.textLabel.text = cModel.url.host;
    
    NSString *detailText;
    if (_transaction.transactionState == CCNetworkTransactionStateFinished || _transaction.transactionState == CCNetworkTransactionStateFailed) {
        detailText = [NSString stringWithFormat:@"%@ %@ %@ ",cModel.method,cModel.statusCode,cModel.showTotalDuration];
    }else{
        NSString *state = [CCNetworkTransaction readableStringFromTransactionState:_transaction.transactionState];
        detailText = [NSString stringWithFormat:@"%@ %@",cModel.method,state];
    }
    
    NSMutableAttributedString *detailAtt = [[NSMutableAttributedString alloc] initWithString:detailText];
    [detailAtt addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, detailText.length)];
    if ([cModel.statusCode integerValue] != 200) {
        [detailAtt addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(cModel.method.length + 1, cModel.statusCode.length)];
    }
    
    self.detailTextLabel.attributedText = detailAtt;
//    self.imageView.image = cModel.responseThumbnail;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    const CGFloat kLeftPadding = 10.0;
    
//    CGRect imageViewFrame = self.imageView.frame;
//    imageViewFrame.origin.x = kLeftPadding;
//    imageViewFrame.origin.y = 5;
//    imageViewFrame.size = CGSizeMake(imageViewFrame.size.width - kLeftPadding, imageViewFrame.size.height - kLeftPadding);
//    self.imageView.frame = imageViewFrame;
    
    CGRect textLabelFrame = self.textLabel.frame;
//    textLabelFrame.origin.x = imageViewFrame.origin.x + imageViewFrame.size.width + kLeftPadding;
    textLabelFrame.origin.y = 7;
    self.textLabel.frame = textLabelFrame;
    
    CGRect detailTextLabelFrame = self.detailTextLabel.frame;
//    detailTextLabelFrame.origin.x = imageViewFrame.origin.x + imageViewFrame.size.width + kLeftPadding;
    detailTextLabelFrame.origin.y = textLabelFrame.origin.y + textLabelFrame.size.height + 5;
    self.detailTextLabel.frame = detailTextLabelFrame;
}

@end
