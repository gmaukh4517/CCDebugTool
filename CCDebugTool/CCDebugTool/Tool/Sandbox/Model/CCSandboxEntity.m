//
//  SandboxEntity.m
//  CCDebugTool
//
//  Created by CC on 2017/11/3.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCSandboxEntity.h"

@implementation CCSandboxEntity

- (void)setType:(NSString *)extended
{
    if (!extended) {
        _fileType = CCFileTypeDirectory;
        return;
    }
    
    extended = extended.uppercaseString;
    CCFileType type = CCFileTypeFile;
    if ([extended isEqualToString:@"EXCEL"] || [extended isEqualToString:@"XLSX"]) {
        type = CCFileTypeExcel;
    } else if ([extended isEqualToString:@"WORD"] || [extended isEqualToString:@"DOC"] ||
              [extended isEqualToString:@"DOCX"]){
        type = CCFileTypeWord;
    } else if ([extended isEqualToString:@"PDF"]){
        type = CCFileTypePDF;
    } else if ([extended isEqualToString:@"ZIP"] || [extended isEqualToString:@"RAR"]){
        type = CCFileTypeZIP;
    } else if ([extended isEqualToString:@"BUNDLE"]){
        type = CCFileTypeBundle;
    } else if ([extended isEqualToString:@"PNG"] || [extended isEqualToString:@"JPG"] ||
               [extended isEqualToString:@"GIF"] || [extended isEqualToString:@"JPEG"]){
        type = CCFileTypeImage;
    } else if ([extended isEqualToString:@"MP3"]){
        type = CCFileTypeMP3;
    } else if ([extended isEqualToString:@"LOG"]){
        type = CCFileTypeLog;
    } else if ([extended isEqualToString:@"PLIST"]){
        type = CCFileTypePlist;
    } else if ([extended isEqualToString:@"SQLITE"] || [extended isEqualToString:@"DB"]){
        type = CCFileTypeSQLite;
    } else if ([extended isEqualToString:@"PPTX"] || [extended isEqualToString:@"PPT"]){
        type = CCFileTypePPT;
    }
    _fileType = type;
}

- (void)setDate:(NSDate *)date
{
    NSDateFormatter *mDateFormatter = [[NSDateFormatter alloc] init];
    [mDateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [mDateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [mDateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss"];
    _fileDate = [mDateFormatter stringFromDate:date];
}

@end
