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
    
    NSString *detailText = [NSString stringWithFormat:@"%@ %@ %@ ",cModel.method,cModel.statusCode,cModel.showTotalDuration];
    
    NSMutableAttributedString *detailAtt = [[NSMutableAttributedString alloc] initWithString:detailText];
    [detailAtt addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, detailText.length)];
    if ([cModel.statusCode integerValue] != 200) {
        [detailAtt addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(cModel.method.length + 1, cModel.statusCode.length)];
    }
    
    self.detailTextLabel.attributedText = detailAtt;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect textLabelFrame = self.textLabel.frame;
    textLabelFrame.origin.y = 7;
    self.textLabel.frame = textLabelFrame;
    
    CGRect detailTextLabelFrame = self.detailTextLabel.frame;
    detailTextLabelFrame.origin.y = textLabelFrame.origin.y + textLabelFrame.size.height + 5;
    self.detailTextLabel.frame = detailTextLabelFrame;
}

@end
