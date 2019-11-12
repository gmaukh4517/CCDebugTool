//
//  CCWebLogMonitoring.h
//  CCDebugTool
//
//  Created by CC on 2019/11/8.
//  Copyright © 2019 CC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCWebLogMonitoring : NSObject

+ (instancetype)manager;

/** 获取日志信息 **/
+ (NSArray *)obtainWebLogs;

@end

NS_ASSUME_NONNULL_END
