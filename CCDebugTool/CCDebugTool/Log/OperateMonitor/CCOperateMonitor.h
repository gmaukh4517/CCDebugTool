//
//  CCOperateMonitor.h
//  CCDebugTool
//
//  Created by CC on 2019/11/18.
//  Copyright © 2019 CC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCOperateMonitor : NSObject

@property (nonatomic, copy) NSString *webCurrentURL;

+ (instancetype)manager;

- (void)setWebCurrentURL:(NSString *)webCurrentURL;

- (void)webOperateEnd;

/** 写入日志 **/
- (void)appOperateLogWrite:(NSString *)log;

/** 写入日志 **/
- (void)webOperateLogWrite:(NSString *)log;

/** 获取日志信息 **/
+ (NSArray *)obtainLogs;

@end

NS_ASSUME_NONNULL_END
