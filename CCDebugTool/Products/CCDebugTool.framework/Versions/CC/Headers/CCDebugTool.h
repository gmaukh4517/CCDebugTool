//
//  CCDebugTool.h
//  CCKit
//
// Copyright (c) 2015 CC ( https://github.com/gmaukh4517/CCKit )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef CCDebugTool_h
#define CCDebugTool_h

#define kCCNotifyKeyReloadHttp @"kCCNotifyKeyReloadHttp"

@interface CCDebugTool : NSObject

/** 主色调 **/
@property (nonatomic, copy) UIColor *mainColor;

/** 日志最大数量，默认20条 **/
@property (nonatomic, assign) NSInteger maxLogsCount;

/** Crash日志最大数量，默认20条  **/
@property (nonatomic, assign) NSInteger maxCrashCount;

/** 设置只抓取的域名，忽略大小写，默认抓取所有 **/
@property (nonatomic, strong) NSArray *arrOnlyHosts;

+ (instancetype)manager;

/** 启动Debug检测 **/
- (void)enableDebugMode;

/**
 设置服务配置参数多个

 @param parameters 配置
 @{ @"id":@"自定义唯一ID",
    @"title":@“显示配置标题”,
    @"parameter":@{@"所需Key":@"所需value"}}
 id : 用于区分 （提供编辑功能，不定义以免出现重复）
 Key : 自定义获取的参数
 Value : 自定义获取的参数值
 */
- (void)setServiceParameters:(NSArray<NSDictionary *> *)parameters;
- (NSDictionary *)getServiceParameter;

/** 卡顿日志 **/
- (NSArray *)CatonLogger;

/** 奔溃日志 **/
- (NSArray *)CrashLogger;

+ (UIImage *)cc_bundle:(NSString *)fileName;

+ (UIImage *)cc_bundle:(NSString *)fileName
           inDirectory:(NSString *)inDirectory;

@end

#endif
