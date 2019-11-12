//
//  CCWebLogMonitoring.m
//  CCDebugTool
//
//  Created by CC on 2019/11/8.
//  Copyright © 2019 CC. All rights reserved.
//

#import "CCWebLogMonitoring.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>

#define HookLogKeys @[ \
@"error",          \
@"info",           \
@"log",            \
@"warn",           \
@"debug"           \
]

static inline void AutomaticWritingSwizzleSelector(Class class, SEL originalSelector, SEL swizzledSelector)
{
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    if (class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

static inline NSString *currentTime()
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSSSSZ"];
    NSString *dateTimeStr = [dateFormatter stringFromDate:[NSDate date]];
    return dateTimeStr;
}

const int webMaxLogSize = 3; // 日志文件最大 3M

#define weblogPlistName @"CCWebLog.plist"

#define kWebLogCatalog [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"CCLog"]

@interface CCWebLogMonitoring ()

@property (nonatomic, copy) NSString *timeStr;

@property (nonatomic, strong) NSMutableArray *logPlist;

@end

@implementation CCWebLogMonitoring

+ (instancetype)manager
{
    static CCWebLogMonitoring *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CCWebLogMonitoring new];
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

+ (NSString *)dateToString:(NSDate *)date
                 formatter:(NSString *)formatter
{
    NSDateFormatter *mDateFormatter = [[NSDateFormatter alloc] init];
    [mDateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [mDateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [mDateFormatter setDateFormat:formatter];
    return [mDateFormatter stringFromDate:date];
}

- (void)initialization
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:kWebLogCatalog]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:kWebLogCatalog
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:[kWebLogCatalog stringByAppendingPathComponent:weblogPlistName]])
        _logPlist = [[NSMutableArray arrayWithContentsOfFile:[kWebLogCatalog stringByAppendingPathComponent:weblogPlistName]] mutableCopy];
    else
        _logPlist = [NSMutableArray new];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    _timeStr = [formatter stringFromDate:[NSDate date]];
}

- (NSString *)newLogFile
{
    NSString *logfileName = [@"Web - " stringByAppendingString:[[CCWebLogMonitoring dateToString:[NSDate date] formatter:@"yyyyMMddHHmmssSSS"] stringByAppendingString:@".log"]];
    [_logPlist insertObject:logfileName atIndex:0];
    [_logPlist writeToFile:[kWebLogCatalog stringByAppendingPathComponent:weblogPlistName] atomically:YES];

    NSString *fliePath = [kWebLogCatalog stringByAppendingPathComponent:logfileName];
    [[NSFileManager defaultManager] createFileAtPath:fliePath contents:nil attributes:nil];
    return fliePath;
}

/** 写入日志 **/
- (void)logWrite:(NSString *)log
{
    NSString *saceCrashPath;
    if (_logPlist.count > 0) {
        saceCrashPath = [kWebLogCatalog stringByAppendingPathComponent:_logPlist.firstObject];

        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:saceCrashPath error:nil];
        NSInteger fileSize = [[fileAttributes objectForKey:NSFileSize] integerValue];
        NSDate *creationDate = [fileAttributes objectForKey:NSFileCreationDate];


        NSDate *todate = [NSDate date]; //今天
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierChinese];
        NSDateComponents *comps_today = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday)
                                                    fromDate:todate];
        NSDateComponents *comps_other = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday)
                                                    fromDate:creationDate];

        if (comps_today.year == comps_other.year &&
            comps_today.month == comps_other.month &&
            comps_today.day == comps_other.day) {
            if (fileSize >= (webMaxLogSize * 1024 * 1024))
                saceCrashPath = [self newLogFile];
        } else
            saceCrashPath = [self newLogFile];
    } else {
        saceCrashPath = [self newLogFile];
    }

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:saceCrashPath];
    [fileHandle seekToEndOfFile];
    log = [log stringByAppendingString:@"\t\n "];
    [fileHandle writeData:[log dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle closeFile];
}

/** 获取日志信息 **/
+ (NSArray *)obtainWebLogs
{
    NSArray *LogPlist = [[NSMutableArray arrayWithContentsOfFile:[kWebLogCatalog stringByAppendingPathComponent:weblogPlistName]] mutableCopy];

    NSMutableArray *logsArray = [NSMutableArray array];
    for (NSString *key in LogPlist) {
        NSString *subPath = [kWebLogCatalog stringByAppendingPathComponent:key];

        NSMutableDictionary *fileDic = [NSMutableDictionary dictionary];
        [fileDic setObject:key forKey:@"fileName"];
        NSArray *dataArr = [[NSString stringWithContentsOfFile:subPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\t\n "];
        [fileDic setObject:dataArr forKey:@"dataArr"];
        [logsArray addObject:fileDic];
    }
    [logsArray sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:NO] ]];

    return [logsArray copy];
}


@end

#pragma mark - WekWebView

@interface CCHookLogHandler : NSObject <WKScriptMessageHandler>

@property (nonatomic, weak) WKWebView *wkWebView;

@end

@implementation CCHookLogHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([HookLogKeys containsObject:message.name]) {
        [[CCWebLogMonitoring manager] logWrite:[NSString stringWithFormat:@"%@ [ WKWebView ] %@ %@", currentTime(), message.name, message.body]];
    }
}

@end

@implementation WKUserContentController (CCHookLog)


+ (void)load
{
    AutomaticWritingSwizzleSelector([self class], @selector(init), @selector(hook_Log_init));
    AutomaticWritingSwizzleSelector([self class], NSSelectorFromString(@"dealloc"), @selector(hook_Log_dealloc));
}

- (instancetype)hook_Log_init
{
    WKUserContentController *wKUserContentController = [self hook_Log_init];
    [wKUserContentController cc_installHookLog];
    return wKUserContentController;
}

- (void)hook_Log_dealloc
{
    [self cc_uninstallHookLog];
}

static const void *CCHookLogKey = &CCHookLogKey;
- (void)cc_uninstallHookLog
{
    for (NSString *key in HookLogKeys) {
        [self removeScriptMessageHandlerForName:key];
    }
    objc_setAssociatedObject(self, CCHookLogKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cc_installHookLog
{
    if ([objc_getAssociatedObject(self, CCHookLogKey) boolValue])
        return;

    objc_setAssociatedObject(self, CCHookLogKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    CCHookLogHandler *handler = [CCHookLogHandler new];
    [self hookLogJS:handler];
}

- (void)hookLogJS:(CCHookLogHandler *)handler
{
    NSString *hookConsoleJS = @"console.{0} = (function(oriLogFunc){\
    return function(str)\
    {\
    window.webkit.messageHandlers.{0}.postMessage(str);\
    oriLogFunc.call(console,str);\
    }\
    })(console.{0});";

    for (NSString *key in HookLogKeys) {
        [self removeScriptMessageHandlerForName:key];
        [self addScriptMessageHandler:handler name:key];
        [self addUserScript:[[WKUserScript alloc] initWithSource:[hookConsoleJS stringByReplacingOccurrencesOfString:@"{0}" withString:key] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO]];
    }
}

@end

#pragma mark - UIWebView

@implementation UIWebView (CCHookLog)

+ (void)load
{
    AutomaticWritingSwizzleSelector([self class], @selector(init), @selector(hook_WebLog_init));
}

- (instancetype)hook_WebLog_init
{
    dispatch_async(dispatch_get_main_queue(), ^{
        JSContext *context = [self valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
        context.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
            context.exception = exceptionValue;
            NSLog(@"异常信息：%@", exceptionValue);
        };

        for (NSString *key in HookLogKeys) {
            context[ @"console" ][ key ] = ^(JSValue *message) {
                id format = [message toString];
                if ([format isEqualToString:@"[object Object]"])
                    format = [message toDictionary];
                [[CCWebLogMonitoring manager] logWrite:[NSString stringWithFormat:@"%@ [ UIWebView ] %@ %@", currentTime(), key, format]];
            };
        }
    });
    return [self hook_WebLog_init];
}

@end
