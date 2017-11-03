//
//  SandboxCollectionViewCell.m
//  CCDebugTool
//
//  Created by CC on 2017/11/3.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "SandboxCollectionViewCell.h"

@interface SandboxCollectionViewCell ()

@property (nonatomic, weak) UILabel *titleLabel;

@property(nonatomic, weak) UIImageView *separateImageView;

@end

@implementation SandboxCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self =  [super initWithFrame:frame]) {
        UILabel *titleLabel = [UILabel new];
        titleLabel.font = [UIFont systemFontOfSize:15];
        [self.contentView addSubview:_titleLabel = titleLabel];
        
        UIImageView *separateImageView = [UIImageView new];
        NSBundle *bundle =  [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"CCDebugTool" withExtension:@"bundle"]];
        separateImageView.image = [UIImage imageWithContentsOfFile:[[bundle resourcePath] stringByAppendingPathComponent:@"TableViewArrow"]];
        [separateImageView sizeToFit];
        [self.contentView addSubview:_separateImageView = separateImageView];
    }
    return self;
}


-(void)cc_cellWillDisplayWithModel:(SandboxEntity *)entity isSelected:(BOOL)selected
{
    self.titleLabel.text = entity.fileName;
    [self.titleLabel sizeToFit];
    self.titleLabel.textColor = [UIColor colorWithRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:153.0 / 255.0];
    self.separateImageView.hidden = NO;
    if (selected) {
        self.titleLabel.textColor =  [UIColor whiteColor];
        self.separateImageView.hidden = YES;
    }
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect titleLabelFrame = self.titleLabel.frame;
    titleLabelFrame.origin.x = 10;
    titleLabelFrame.origin.y = (self.bounds.size.height - titleLabelFrame.size.height) / 2;
    self.titleLabel.frame = titleLabelFrame;
    
    CGRect separateImageViewFrame = self.separateImageView.frame;
    separateImageViewFrame.origin.x = self.bounds.size.width - separateImageViewFrame.size.width + 5;
    separateImageViewFrame.origin.y = (self.bounds.size.height - separateImageViewFrame.size.height) / 2;
    self.separateImageView.frame = separateImageViewFrame;
}

@end
