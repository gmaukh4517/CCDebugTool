//
//  SandboxTableViewCell.m
//  CCDebugTool
//
//  Created by CC on 2017/11/3.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCSandboxTableViewCell.h"
#import "CCDebugTool.h"

@implementation CCSandboxTableViewCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.textLabel.textColor = [CCDebugTool manager].mainColor;
        self.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:19];
    }
    return self;
}

-(void)cc_cellWillDisplayWithModel:(CCSandboxEntity *)entity
{
    self.textLabel.text = entity.fileName;
    self.imageView.image = [self typeImage:entity.fileType];
    self.detailTextLabel.text = entity.fileDate;
    
    self.accessoryType = UITableViewCellAccessoryNone;
    if (entity.fileType == CCFileTypeDirectory)
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

-(UIImage *)typeImage:(CCFileType)type
{
    NSBundle *bundle =  [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"CCDebugTool" withExtension:@"bundle"]];
    NSString *fileName = @"";
    switch (type) {
        case CCFileTypeBundle:
            fileName = @"cc_bundle";
            break;
        case CCFileTypeDirectory:
            fileName = @"cc_directory";
            break;
        case CCFileTypeExcel:
            fileName = @"cc_excel";
            break;
        case CCFileTypeFile:
            fileName = @"cc_file";
            break;
        case CCFileTypeImage:
            fileName = @"cc_image";
            break;
        case CCFileTypeLog:
            fileName = @"cc_log";
            break;
        case CCFileTypeMP3:
            fileName = @"cc_mp3";
            break;
        case CCFileTypePlist:
            fileName = @"cc_plist";
            break;
        case CCFileTypePPT:
            fileName = @"cc_ppt";
            break;
        case CCFileTypeSQLite:
           fileName = @"cc_sqlite";
            break;
        case CCFileTypeWord:
            fileName = @"cc_word";
            break;
        case CCFileTypeZIP:
            fileName = @"cc_zip";
            break;
        case CCFileTypePDF:
            fileName = @"cc_bundle";
            break;
        default:
            break;
    }
    
    return [UIImage imageWithContentsOfFile:[[bundle resourcePath] stringByAppendingPathComponent:fileName]];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    CGRect imageFrame = self.imageView.frame;
    imageFrame.origin.x = 10;
    imageFrame.size.width = 55;
    imageFrame.size.height = 55;
    self.imageView.frame = imageFrame;
    self.imageView.center = CGPointMake(self.imageView.center.x, self.contentView.center.y);
    
    CGRect textLabelFrame = self.textLabel.frame;
    textLabelFrame.origin.x = imageFrame.origin.x + imageFrame.size.width + 10;
    textLabelFrame.origin.y = imageFrame.origin.y - 5;
    self.textLabel.frame = textLabelFrame;
    
    CGRect detailTextLabelFrame = self.detailTextLabel.frame;
    detailTextLabelFrame.origin.x = textLabelFrame.origin.x;
    detailTextLabelFrame.origin.y = detailTextLabelFrame.origin.y + 5;
    self.detailTextLabel.frame = detailTextLabelFrame;
}

@end
