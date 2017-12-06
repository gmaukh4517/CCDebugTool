//
//  DatabaseTableViewCell.m
//  CCDebugTool
//
//  Created by CC on 2017/12/6.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "DatabaseTableViewCell.h"

@implementation DatabaseTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.textLabel.font = [UIFont systemFontOfSize:14];
        self.textLabel.textColor = [UIColor grayColor];
    }
    return self;
}

-(void)cc_cellWillDisplayWithModel:(NSString *)text
{
    self.textLabel.text = text;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect frame = self.textLabel.frame;
    frame.origin.x = 5;
    frame.size.width = self.bounds.size.width - 10;
    self.textLabel.frame = frame;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
