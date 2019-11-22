//
//  CCStatistics.h
//  CCDebugTool
//
//  Created by CC on 2019/11/18.
//  Copyright © 2019 CC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCStatistics : NSObject

+ (instancetype)manager;

- (NSDictionary *)obtainStatistics;

/// 页面进入时间
/// @param key 页面名称
- (void)viewControllerEnter:(NSString *)key;

/// 页面加载时间
/// @param key 页面名称
- (void)viewControllerAppear:(NSString *)key;

/// 页面退出时间
/// @param key 页面名称
- (void)viewControllerExit:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
