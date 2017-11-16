//
//  CCAppFluecyMonitor.m
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

#import "CCAppFluecyMonitor.h"
#import "CCBacktraceLogger.h"
#import "CCDebugFluencyHelper.h"

@interface CCAppFluecyMonitor ()

@property (nonatomic, assign) int timeOut;
@property (nonatomic, assign) BOOL isMonitoring;

@property (nonatomic, assign) CFRunLoopObserverRef observer;
@property (nonatomic, assign) CFRunLoopActivity currentActivity;

@property (nonatomic, strong) dispatch_semaphore_t semphore;
@property (nonatomic, strong) dispatch_semaphore_t eventSemphore;

@end

#define CC_SEMPHORE_SUCCESS 0
static NSTimeInterval cc_restore_interval = 5;
static NSTimeInterval cc_time_out_interval = 1;
static int64_t cc_wait_interval = 200 * NSEC_PER_MSEC;


/*!
 *  @brief  监听runloop状态为before waiting状态下是否卡顿
 */
static inline dispatch_queue_t cc_event_monitor_queue()
{
    static dispatch_queue_t cc_event_monitor_queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cc_event_monitor_queue = dispatch_queue_create("com.sindrilin.cc_event_monitor_queue", NULL);
    });
    return cc_event_monitor_queue;
}

/*!
 *  @brief  监听runloop状态在after waiting和before sources之间
 */
static inline dispatch_queue_t cc_fluecy_monitor_queue()
{
    static dispatch_queue_t cc_fluecy_monitor_queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cc_fluecy_monitor_queue = dispatch_queue_create("com.sindrilin.cc_monitor_queue", NULL);
    });
    return cc_fluecy_monitor_queue;
}

#define LOG_RUNLOOP_ACTIVITY 0
static void ccRunLoopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    SHAREDMONITOR.currentActivity = activity;
    dispatch_semaphore_signal(SHAREDMONITOR.semphore);
#if LOG_RUNLOOP_ACTIVITY
    switch (activity) {
        case kCFRunLoopEntry:
            NSLog(@"runloop entry");
            break;
            
        case kCFRunLoopExit:
            NSLog(@"runloop exit");
            break;
            
        case kCFRunLoopAfterWaiting:
            NSLog(@"runloop after waiting");
            break;
            
        case kCFRunLoopBeforeTimers:
            NSLog(@"runloop before timers");
            break;
            
        case kCFRunLoopBeforeSources:
            NSLog(@"runloop before sources");
            break;
            
        case kCFRunLoopBeforeWaiting:
            NSLog(@"runloop before waiting");
            break;
            
        default:
            break;
    }
#endif
};


@implementation CCAppFluecyMonitor

#pragma mark - Singleton override
+ (instancetype)sharedMonitor
{
    static CCAppFluecyMonitor *sharedMonitor;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedMonitor = [[super allocWithZone:NSDefaultMallocZone()] init];
        [sharedMonitor commonInit];
    });
    return sharedMonitor;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [self sharedMonitor];
}

- (void)dealloc
{
    [self stopMonitoring];
}

- (void)commonInit
{
    self.semphore = dispatch_semaphore_create(0);
    self.eventSemphore = dispatch_semaphore_create(0);
}


#pragma mark - Public
- (void)startMonitoring
{
    if (_isMonitoring) {
        return;
    }
    _isMonitoring = YES;
    CFRunLoopObserverContext context = {
        0,
        (__bridge void *)self,
        NULL,
        NULL};
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &ccRunLoopObserverCallback, &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    
    dispatch_async(cc_event_monitor_queue(), ^{
        while (SHAREDMONITOR.isMonitoring) {
            if (SHAREDMONITOR.currentActivity == kCFRunLoopBeforeWaiting) {
                __block BOOL timeOut = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    timeOut = NO;
                    dispatch_semaphore_signal(SHAREDMONITOR.eventSemphore);
                });
                [NSThread sleepForTimeInterval:cc_time_out_interval];
                
                if (timeOut)
                    [self backtraceLoggerHandle];
                
                dispatch_wait(SHAREDMONITOR.eventSemphore, DISPATCH_TIME_FOREVER);
            }
        }
    });
    
    dispatch_async(cc_fluecy_monitor_queue(), ^{
        while (SHAREDMONITOR.isMonitoring) {
            long waitTime = dispatch_semaphore_wait(self.semphore, dispatch_time(DISPATCH_TIME_NOW, cc_wait_interval));
            if (waitTime != CC_SEMPHORE_SUCCESS) {
                if (!SHAREDMONITOR.observer) {
                    SHAREDMONITOR.timeOut = 0;
                    [SHAREDMONITOR stopMonitoring];
                    continue;
                }
                if (SHAREDMONITOR.currentActivity == kCFRunLoopBeforeSources || SHAREDMONITOR.currentActivity == kCFRunLoopAfterWaiting) {
                    if (++SHAREDMONITOR.timeOut < 5)
                        continue;
                    
                    [self backtraceLoggerHandle];
                    
                    [NSThread sleepForTimeInterval:cc_restore_interval];
                }
            }
            SHAREDMONITOR.timeOut = 0;
        }
    });
}

- (void)stopMonitoring
{
    if (!_isMonitoring) {
        return;
    }
    _isMonitoring = NO;
    
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = nil;
}

- (void)backtraceLoggerHandle
{
    NSMutableDictionary *catonDic = [NSMutableDictionary dictionary];
    //    [carsDic setObject:[exception reason] forKey:@"ErrCause"];
    [catonDic setObject:[NSDate date] forKey:@"ErrDate"];
    [catonDic setObject:[CCBacktraceLogger cc_backtraceOfMainThread] forKey:@"ErrMsg"];
    
    [[CCDebugFluencyHelper manager] saveFluencyException:catonDic];
}

+ (NSArray *)obtainFluencyLogs
{
    return [CCDebugFluencyHelper obtainFluencyLogs];
}

@end
