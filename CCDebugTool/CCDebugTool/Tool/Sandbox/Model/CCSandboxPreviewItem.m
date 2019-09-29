//
//  CCPreviewItem.m
//  CCDebugTool
//
//  Created by CC on 2018/7/7.
//  Copyright © 2018年 CC. All rights reserved.
//

#import "CCSandboxPreviewItem.h"

@implementation CCSandboxPreviewItem

@synthesize previewItemURL = _previewItemURL;

+ (CCSandboxPreviewItem *)previewItemWithPaht:(NSString *)path
                                 title:(NSString *)title
{
    return [self previewItemWithURL:[NSURL fileURLWithPath:path]
                              title:title];
}

+ (CCSandboxPreviewItem *)previewItemWithURL:(NSURL *)url
                                title:(NSString *)title
{
    CCSandboxPreviewItem *instance = [[CCSandboxPreviewItem alloc] init];
    instance.previewItemURL = url;
    instance.previewItemTitle = title;

    return instance;
}

@end
