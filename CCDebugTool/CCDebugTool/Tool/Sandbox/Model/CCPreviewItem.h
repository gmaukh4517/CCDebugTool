//
//  CCPreviewItem.h
//  CCDebugTool
//
//  Created by CC on 2018/7/7.
//  Copyright © 2018年 CC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>

@interface CCPreviewItem : NSObject<QLPreviewItem>

@property(nonatomic,readwrite) NSURL *previewItemURL;
@property(nonatomic,readwrite) NSString *previewItemTitle;

+ (CCPreviewItem *)previewItemWithPaht:(NSString *)path
                                title:(NSString *)title;

+ (CCPreviewItem *)previewItemWithURL:(NSURL *)urlStr
                                title:(NSString *)title;

@end
