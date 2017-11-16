//
//  CCDebugLogHelper.h
//  CCDebugTool
//
//  Created by CC on 2017/11/16.
//  Copyright © 2017年 CC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCLogMonitoring : NSObject

+ (instancetype)manager;

/** 获取日志信息 **/
+ (NSArray *)obtainLogs;

-(void)startMonitoring;

@end
