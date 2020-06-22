//
//  CCStatistics.m
//  CCDebugTool
//
//  Created by CC on 2019/11/18.
//  Copyright © 2019 CC. All rights reserved.
//

#import "CCStatistics.h"
#import <CommonCrypto/CommonDigest.h>

@interface CCStatistics ()

@property (nonatomic, strong) NSMutableDictionary *statisticsDic;

@property (nonatomic, strong) NSDate *aliveDate; // 程序进入前台时刻
@property (nonatomic, strong) NSDate *backDate;  // 程序进入后台时刻

@end

@implementation CCStatistics

+ (instancetype)manager
{
    static CCStatistics *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CCStatistics new];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self initialization];
    }
    return self;
}

- (void)initialization
{
    _statisticsDic = [NSMutableDictionary dictionary];
}

- (void)addAppStatusNoticefication
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

/*
 程序进程结束即退出程序
 */
- (void)onAppWillTerminate:(NSNotification *)notification
{
    for (NSString *key in self.statisticsDic.allKeys) {
        NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[self.statisticsDic objectForKey:key]];
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:[item objectForKey:@"EnterDate"]];
        
        /*
         当使用过程中程序进入后台并停留一段时间时，统计时长需要减去该段时间
         */
        if (self.backDate && ([self.backDate timeIntervalSinceDate:[item objectForKey:@"EnterDate"]] > 0)) {
            duration = duration - [[NSDate date] timeIntervalSinceDate:self.backDate];
        }
        [item setObject:@(duration) forKey:@"StatisticDuration"];
        [self.statisticsDic setObject:item forKey:key];
    }
}

/*
 程序进入前台
 */
- (void)onAppDidBecomeActive:(NSNotification *)notification
{
    self.aliveDate = [NSDate date];
}

/*
 程序进入后台
 */
- (void)onAppDidEnterBackground:(NSNotification *)notification
{
    self.backDate = [NSDate date];
}

- (NSDictionary *)obtainStatistics
{
    return self.statisticsDic;
}

- (NSString *)MD5:(NSString *)key
{
    const char *string = key.UTF8String;
    int length = (int)strlen(string);
    unsigned char bytes[ CC_MD5_DIGEST_LENGTH ];
    CC_MD5(string, length, bytes);
    
    NSMutableString *mutableString = @"".mutableCopy;
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [mutableString appendFormat:@"%02x", bytes[ i ]];
    return [NSString stringWithString:mutableString];
}

/// 页面进入时间
/// @param key 页面名称
- (void)viewControllerEnter:(NSString *)key
{
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[_statisticsDic objectForKey:[self MD5:key]]];
    [item setObject:key forKey:@"key"];
    
    NSInteger enterCount = [[item objectForKey:@"enterCount"] integerValue];
    [item setObject:@(enterCount + 1) forKey:@"enterCount"];
    [item setObject:[NSDate date] forKey:@"enterDate"];
    
    [_statisticsDic setObject:item forKey:[self MD5:key]];
}

/// 页面加载时间
/// @param key 页面名称
- (void)viewControllerAppear:(NSString *)key
{
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[_statisticsDic objectForKey:[self MD5:key]]];
    if (!item.allKeys.count)
        return;
    
    NSDate *date = [item objectForKey:@"enterDate"];
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:date];
    if (self.backDate && ([self.backDate timeIntervalSinceDate:date] > 0))
        duration = duration - [self.aliveDate timeIntervalSinceDate:self.backDate];
    [item setObject:@(duration) forKey:@"appearDuration"];
    
    //总渲染留时间
    NSTimeInterval totalAppearTime = [[item objectForKey:@"totalAppearTime"] doubleValue];
    totalAppearTime += duration;
    [item setObject:@(totalAppearTime) forKey:@"totalAppearTime"];
    
    [_statisticsDic setObject:item forKey:[self MD5:key]];
}

/// 页面退出时间
/// @param key 页面名称
- (void)viewControllerExit:(NSString *)key
{
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[_statisticsDic objectForKey:[self MD5:key]]];
    if (!item.allKeys.count)
        return;
    
    NSDate *date = [item objectForKey:@"enterDate"];
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:date];
    if (self.backDate && ([self.backDate timeIntervalSinceDate:date] > 0))
        duration = duration - [self.aliveDate timeIntervalSinceDate:self.backDate];
    [item setObject:@(duration) forKey:@"statisticDuration"];
    
    //总停留时间
    NSTimeInterval totalTime = [[item objectForKey:@"totalTime"] doubleValue];
    totalTime += duration;
    [item setObject:@(totalTime) forKey:@"totalTime"];
    
    [_statisticsDic setObject:item forKey:[self MD5:key]];
}

@end
