//
//  SandboxEntity.h
//  CCDebugTool
//
//  Created by CC on 2017/11/3.
//  Copyright © 2017年 CC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,CCFileType) {
    CCFileTypeDirectory = 0,
    CCFileTypeBundle,
    CCFileTypeExcel,
    CCFileTypeFile,
    CCFileTypeImage,
    CCFileTypeLog,
    CCFileTypeMP3,
    CCFileTypePlist,
    CCFileTypePPT,
    CCFileTypeSQLite,
    CCFileTypeWord,
    CCFileTypeZIP,
    CCFileTypePDF,
};

@interface CCSandboxEntity : NSObject

@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) NSInteger fileSize;
@property (nonatomic, copy) NSString *fileDate;
@property (nonatomic, assign) CCFileType fileType;

- (void)setType:(NSString *)extended;
- (void)setDate:(NSDate *)date;

@end
