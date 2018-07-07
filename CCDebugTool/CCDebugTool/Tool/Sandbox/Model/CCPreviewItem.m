//
//  CCPreviewItem.m
//  CCDebugTool
//
//  Created by CC on 2018/7/7.
//  Copyright © 2018年 CC. All rights reserved.
//

#import "CCPreviewItem.h"

@implementation CCPreviewItem

@synthesize previewItemURL = _previewItemURL;

+ (CCPreviewItem *)previewItemWithPaht:(NSString *)path
                                 title:(NSString *)title
{
    return [self previewItemWithURL:[NSURL fileURLWithPath:path]
                              title:title];
}

+ (CCPreviewItem *)previewItemWithURL:(NSURL *)url
                                title:(NSString *)title
{
    CCPreviewItem *instance = [[CCPreviewItem alloc] init];
    instance.previewItemURL = url;
    instance.previewItemTitle = title;

    return instance;
}

@end
