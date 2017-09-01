//
//  CCMonitorService.m
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

#import "CCMonitorService.h"
#import "CCMonitorHelper.h"
#import "CCPerformanceConfig.h"
#import "CCPerformanceStatusBar.h"
#import "Reachability.h"

@interface CCMonitorService ()

@property (strong, nonatomic) CADisplayLink *displayLink;

@property (assign, nonatomic) NSTimeInterval lastTimestamp;

@property (assign, nonatomic) NSInteger countPerFrame;

@property (strong, nonatomic) CCPerformanceStatusBar *monitorStatusBar;

@property (strong, nonatomic) UIWindow *statusBarWindow;

@property (strong, nonatomic) NSMutableDictionary *configDictionary;

@property (assign, nonatomic) float preWWAN_R;

@property (assign, nonatomic) float preWWAN_S;

@property (assign, nonatomic) float preWifi_R;

@property (assign, nonatomic) float preWifi_S;

@end

@implementation CCMonitorService

+ (instancetype)sharedService
{
    static CCMonitorService *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CCMonitorService alloc] init];
    });
    return sharedInstance;
}

- (NSMutableDictionary *)configDictionary
{
    if (_configDictionary == nil) {
        _configDictionary = [NSMutableDictionary new];
        [_configDictionary setObject:[CCPerformanceConfig defaultConfigForAttribtue:CCPerformanceMonitorCPU]
                              forKey:@(CCPerformanceMonitorCPU)];
        [_configDictionary setObject:[CCPerformanceConfig defaultConfigForAttribtue:CCPerformanceMonitorFPS]
                              forKey:@(CCPerformanceMonitorFPS)];
        [_configDictionary setObject:[CCPerformanceConfig defaultConfigForAttribtue:CCPerformanceMonitorMemory]
                              forKey:@(CCPerformanceMonitorMemory)];
    }
    return _configDictionary;
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
    [self currentLiuLiang];
    _lastTimestamp = -1;
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(envokeDisplayLink:)];
    _displayLink.paused = YES;
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    //Notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActiveNotification)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActiveNotification)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

- (void)dealloc
{
    _displayLink.paused = YES;
    [_displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)setBarWindow:(UIWindow *)window
{
    self.statusBarWindow = window;
    CGFloat width = 150;
    
    _monitorStatusBar = [[CCPerformanceStatusBar alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width - width) / 2, 2, width, 20)];
    self.statusBarWindow.hidden = YES;
    self.statusBarWindow.windowLevel = UIWindowLevelAlert + 1;
    [self.statusBarWindow addSubview:self.monitorStatusBar];
}

#pragma mark - Private

- (void)start:(UIWindow *)monitorWindow
{
    [self setBarWindow:monitorWindow];
    _displayLink.paused = NO;
    self.statusBarWindow.hidden = NO;
}

- (void)stop
{
    _displayLink.paused = YES;
    self.statusBarWindow.hidden = YES;
}

- (void)setMainColor:(UIColor *)mainColor
{
    self.monitorStatusBar.backgroundColor = mainColor;
}

#pragma mark - DisplayLink hander

- (void)envokeDisplayLink:(CADisplayLink *)displayLink
{
    if (_lastTimestamp == -1) {
        _lastTimestamp = displayLink.timestamp;
        return;
    }
    _countPerFrame++;
    NSTimeInterval interval = displayLink.timestamp - _lastTimestamp;
    if (interval < 1) {
        return;
    }
    _lastTimestamp = displayLink.timestamp;
    CGFloat fps = _countPerFrame / interval;
    _countPerFrame = 0;
    
    self.monitorStatusBar.fpsLabel.text = [NSString stringWithFormat:@"FPS:%d", (int)round(fps)];
    self.monitorStatusBar.fpsLabel.state = [self labelStateWith:CCPerformanceMonitorFPS value:fps];
    
    
    CGFloat cpu = [CCMonitorHelper cpu_usage];
    self.monitorStatusBar.cpuLabel.text = [NSString stringWithFormat:@"CPU:%.2f%%", cpu];
    self.monitorStatusBar.cpuLabel.state = [self labelStateWith:CCPerformanceMonitorCPU value:cpu];
    
    CGFloat ram = [CCMonitorHelper getResidentMemorySize] / 1024.0 / 1024.0;
    self.monitorStatusBar.ramLabel.text = [NSString stringWithFormat:@"RAM:%.1f MB", ram];
    self.monitorStatusBar.ramLabel.state = [self labelStateWith:CCPerformanceMonitorMemory value:ram];
    
    NSString *networkText = @"↑: -/- ↓: -/-";
    Reachability *reachability = [Reachability reachabilityWithHostName:@"hah"];
    if (reachability.currentReachabilityStatus == ReachableViaWiFi) {
        float wifiS_preSecond = [[CCMonitorHelper getDataCounters][0] floatValue] - self.preWifi_S;
        float wifiR_preSecond = [[CCMonitorHelper getDataCounters][1] floatValue] - self.preWifi_R;
        networkText = [NSString stringWithFormat:@"↑: %@ ↓: %@", [self number2String:wifiS_preSecond], [self number2String:wifiR_preSecond]];
    } else if (reachability.currentReachabilityStatus == ReachableViaWWAN) {
        float wwanS_preSecond = [[CCMonitorHelper getDataCounters][2] floatValue] - self.preWWAN_S;
        float wwanR_preSecond = [[CCMonitorHelper getDataCounters][3] floatValue] - self.preWWAN_R;
        networkText = [NSString stringWithFormat:@"↑: %@ ↓: %@", [self number2String:wwanS_preSecond], [self number2String:wwanR_preSecond]];
    } else {
    }
    
    self.monitorStatusBar.networkLabel.text = networkText;
    [self currentLiuLiang];
}


#define KB (1024)
#define MB (KB * 1024)
#define GB (MB * 1024)
- (NSString *)number2String:(float)n
{
    if (n < KB) {
        return [NSString stringWithFormat:@"%.0f B/S", n];
    } else if (n < MB) {
        return [NSString stringWithFormat:@"%.1f KB/S", n / KB];
    } else if (n < GB) {
        return [NSString stringWithFormat:@"%.1f MB/S", n / MB];
    } else {
        return [NSString stringWithFormat:@"%.1f G/S", n / GB];
    }
}


- (void)currentLiuLiang
{
    NSNumber *wifiSendNumber = [CCMonitorHelper getDataCounters][0];
    float wifiS = [wifiSendNumber floatValue];
    self.preWifi_S = wifiS;
    
    NSNumber *wifiReceived = [CCMonitorHelper getDataCounters][1];
    float wifiR = [wifiReceived floatValue];
    self.preWifi_R = wifiR;
    
    NSNumber *wwanSendNumber = [CCMonitorHelper getDataCounters][2];
    float wwanS = [wwanSendNumber floatValue];
    self.preWWAN_S = wwanS;
    
    NSNumber *wwanReceived = [CCMonitorHelper getDataCounters][3];
    float wwanR = [wwanReceived floatValue];
    self.preWWAN_R = wwanR;
}

#pragma mark - Calculator

- (CCPerformanceLabelState)labelStateWith:(CCPerformanceMonitorAttributes)attribtue value:(CGFloat)currentValue
{
    CCPerformanceConfig *config = [self.configDictionary objectForKey:@(attribtue)];
    if (!config.lessIsBetter) {
        if (currentValue > config.goodThreshold) {
            return CCPerformanceStateGood;
        } else if (currentValue > config.warningThreadhold) {
            return CCPerformanceStateWarning;
        } else {
            return CCPerformanceStateBad;
        }
    } else {
        if (currentValue < config.goodThreshold) {
            return CCPerformanceStateGood;
        } else if (currentValue < config.warningThreadhold) {
            return CCPerformanceStateWarning;
        } else {
            return CCPerformanceStateBad;
        }
    }
}
#pragma mark - Notification

- (void)applicationDidBecomeActiveNotification
{
    _displayLink.paused = NO;
}

- (void)applicationWillResignActiveNotification
{
    _displayLink.paused = YES;
}

#pragma mark API

+ (void)start:(UIWindow *)monitorWindow
{
    [[CCMonitorService sharedService] start:monitorWindow];
}

+ (void)stop
{
    [[CCMonitorService sharedService] stop];
}

+ (void)mainColor:(UIColor *)color
{
    [[CCMonitorService sharedService] setMainColor:color];
}

@end
