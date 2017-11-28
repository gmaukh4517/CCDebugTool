//
//  CookiesTableViewCell.m
//  CCDebugTool
//
//  Created by CC on 2017/11/21.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCCookiesTableViewCell.h"
#import "CCDebugTool.h"

@implementation CCCookiesTableViewCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.textLabel.textColor = [CCDebugTool manager].mainColor;
        self.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:19];
        self.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    return self;
}

-(void)cc_cellWillDisplayWithModel:(NSHTTPCookie *)entity
{
    self.textLabel.text = entity.domain;
    self.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", entity.name, entity.value];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
