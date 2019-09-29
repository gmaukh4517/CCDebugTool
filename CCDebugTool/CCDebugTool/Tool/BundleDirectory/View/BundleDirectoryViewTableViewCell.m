//
//  BundleDirectoryViewTableViewCell.m
//  CCDebugTool
//
//  Created by CC on 2019/9/12.
//  Copyright © 2019 CC. All rights reserved.
//

#import "BundleDirectoryViewTableViewCell.h"

@implementation BundleDirectoryViewTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        self.imageView.layer.borderColor = UIColor.blackColor.CGColor;
        self.imageView.layer.borderWidth = 0.5;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;

        self.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];

        self.detailTextLabel.font =[UIFont fontWithName:@"HelveticaNeue" size:10];
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    }
    return self;
}

- (void)cc_cellWillDisplayWithModel:(NSDictionary *)item
{
    self.imageView.image = [item objectForKey:@"image"];
    self.textLabel.text = [item objectForKey:@"fileName"];
    self.detailTextLabel.text = [item objectForKey:@"subtitle"];
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
}

@end
