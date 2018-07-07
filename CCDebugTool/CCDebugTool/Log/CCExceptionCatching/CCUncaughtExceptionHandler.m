//
//  UncaughtExceptionHandler.m
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

#import "CCUncaughtExceptionHandler.h"
#import "CCDebugCrashHelper.h"
#import "CCMacros.h"
#import <UIKit/UIKit.h>
#include <execinfo.h>
#include <libkern/OSAtomic.h>
#include <sys/signal.h>

#import "UIControl+CCHook.h"
#import "UIViewController+CCHook.h"

@interface CCUncaughtExceptionHandler () {
    BOOL dismissed;
}
@end


NSString *const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString *const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString *const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;

const NSInteger skipAddressCount = 4;
const NSInteger reportAddressCount = 5;

static NSUncaughtExceptionHandler *previousUncaughtExceptionHandler;
typedef void (*SignalHandler)(int signo, siginfo_t *info, void *context);
static SignalHandler previousSignalHandler = NULL;

@implementation CCUncaughtExceptionHandler

+ (NSArray *)backtrace
{
    void *callstack[ 128 ];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);

    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (int i = skipAddressCount; i < skipAddressCount + reportAddressCount; i++)
        [backtrace addObject:[NSString stringWithUTF8String:strs[ i ]]];
    free(strs);

    return backtrace;
}

- (void)alertView:(UIAlertView *)anAlertView clickedButtonAtIndex:(NSInteger)anIndex
{
    if (anIndex == 0)
        dismissed = YES;
    else if (anIndex == 1)
        NSLog(@"应用继续使用");
}

- (void)setDismissed
{
    dismissed = NO;
}

- (void)validateAndSaveCriticalApplicationData:(NSException *)exception
{
    NSMutableString *errorStr = [NSMutableString string];
    [errorStr appendFormat:@"Name of the device owner: %@ \n", [[UIDevice currentDevice] name]];
    [errorStr appendFormat:@"Device Type：%@ \n", [[UIDevice currentDevice] model]];
    [errorStr appendFormat:@"Hardware Model：%@ \n", hardwareDescription()];
    [errorStr appendFormat:@"Device operation system：%@ \n", [[UIDevice currentDevice] systemName]];
    [errorStr appendFormat:@"Version of the current system：%@ \n", [[UIDevice currentDevice] systemVersion]];
    [errorStr appendFormat:@"Device Identity：%@ \n", [[[UIDevice currentDevice] identifierForVendor] UUIDString]];
    [errorStr appendFormat:@"Application version：%@ \n", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [errorStr appendFormat:@"Application Build version：%@ \n", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    [errorStr appendFormat:@"Device is jailbreak：%@\n", cc_isJailbreak() ? @"NO" : @"YES"];
    [errorStr appendFormat:@"Error Cause：%@\n", [exception reason]];
    [errorStr appendFormat:@"%@ \n", [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey]];

    NSArray *arr = [CCDebugCrashHelper manager].crashLastStep;
    if (arr.count) {
        [errorStr appendString:@"Last Operation：\n"];
        [errorStr appendFormat:@"%@", [arr componentsJoinedByString:@"\n"]];
    }

    NSMutableDictionary *carsDic = [NSMutableDictionary dictionary];
    [carsDic setObject:exception.name forKey:@"ErrName"];
    [carsDic setObject:[exception reason] forKey:@"ErrCause"];
    [carsDic setObject:[NSDate date] forKey:@"ErrDate"];
    [carsDic setObject:errorStr forKey:@"ErrMsg"];
    [carsDic setObject:@"6" forKey:@"ErrType"];

    [[CCDebugCrashHelper manager] saveCrashException:carsDic];

    if (!dismissed) {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"如果点击继续，程序有可能会出现其他的问题，建议您还是点击退出按钮并重新打开\n\n"
                                                                         @"异常原因如下:\n%@\n%@",
                                                                         nil),
                                                       [exception reason], [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"抱歉，程序出现了异常", nil)
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"退出", nil)
                                              otherButtonTitles:NSLocalizedString(@"继续", nil), nil];
        [alert show];
    }
}

/**
 统一错误处理

 @param exception 错误信息
 */
- (void)unifyHandleException:(NSException *)exception
{
    dismissed = YES;
    [self validateAndSaveCriticalApplicationData:exception];

    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);

    while (!dismissed) {
        for (NSString *mode in (__bridge NSArray *)allModes)
            CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
    }

    CFRelease(allModes);

    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);

    if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName])
        kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
    else
        [exception raise];

    [self performSelector:@selector(setDismissed) withObject:nil afterDelay:2];
}

+ (NSArray *)obtainCrashLogs
{
    return [CCDebugCrashHelper obtainCrashLogs];
}

@end

/** 处理奔溃错误事件 **/
void HandleException(NSException *exception)
{
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum)
        return;

    NSArray *callStack = [CCUncaughtExceptionHandler backtrace];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    [userInfo setObject:callStack forKey:UncaughtExceptionHandlerAddressesKey];

    [[[CCUncaughtExceptionHandler alloc] init] performSelectorOnMainThread:@selector(unifyHandleException:)
                                                                withObject:[NSException exceptionWithName:[exception name]
                                                                                                   reason:[exception reason]
                                                                                                 userInfo:userInfo]
                                                             waitUntilDone:YES];
    //覆盖处理
    if (previousUncaughtExceptionHandler) {
        previousUncaughtExceptionHandler(exception);
    }
}

/** 奔溃错误初始化 **/
void CCExceptionRegister(void)
{
    previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();

    NSSetUncaughtExceptionHandler(&HandleException);
}

/** 处理信号量事件 **/
static void CCSignalHandler(int signal, siginfo_t *info, void *context)
{
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum)
        return;

    NSString *description = nil;
    switch (signal) {
        case SIGABRT:
            description = [NSString stringWithFormat:@"Signal SIGABRT was raised!\n"];
            break;
        case SIGILL:
            description = [NSString stringWithFormat:@"Signal SIGILL was raised!\n"];
            break;
        case SIGSEGV:
            description = [NSString stringWithFormat:@"Signal SIGSEGV was raised!\n"];
            break;
        case SIGFPE:
            description = [NSString stringWithFormat:@"Signal SIGFPE was raised!\n"];
            break;
        case SIGBUS:
            description = [NSString stringWithFormat:@"Signal SIGBUS was raised!\n"];
            break;
        case SIGPIPE:
            description = [NSString stringWithFormat:@"Signal SIGPIPE was raised!\n"];
            break;
        default:
            description = [NSString stringWithFormat:@"Signal %d was raised!", signal];
    }


    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:signal] forKey:UncaughtExceptionHandlerSignalKey];

    NSArray *callStack = [CCUncaughtExceptionHandler backtrace];
    [userInfo setObject:callStack forKey:UncaughtExceptionHandlerAddressesKey];

    [[[CCUncaughtExceptionHandler alloc] init] performSelectorOnMainThread:@selector(unifyHandleException:)
                                                                withObject:[NSException exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
                                                                                                   reason:description
                                                                                                 userInfo:userInfo]
                                                             waitUntilDone:YES];


    if (previousSignalHandler) // 传递 handler
        previousSignalHandler(signal, info, context);
}

/** 注册信号量处理事件 **/
void CCSignalRegister(int signal)
{
    struct sigaction action;
    action.sa_sigaction = CCSignalHandler;
    action.sa_flags = SA_NODEFER | SA_SIGINFO;
    sigemptyset(&action.sa_mask);
    sigaction(signal, &action, 0);
}

/** 信号量初始化 **/
void CCSignalInstal(void)
{
    struct sigaction old_action;
    sigaction(SIGABRT, NULL, &old_action);
    if (old_action.sa_flags & SA_SIGINFO)
        previousSignalHandler = old_action.sa_sigaction;

    signal(SIGABRT, CCSignalRegister);
    signal(SIGILL, CCSignalRegister);
    signal(SIGSEGV, CCSignalRegister);
    signal(SIGFPE, CCSignalRegister);
    signal(SIGBUS, CCSignalRegister);
    signal(SIGPIPE, CCSignalRegister);
}

/** 初始化奔溃捕获 **/
void InstalCrashHandler(void)
{
    CCExceptionRegister();
    CCSignalInstal();

    [UIControl CCHook];
    [UIViewController CCHook];
}
