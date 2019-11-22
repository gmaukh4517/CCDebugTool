//
//  CCOperateMonitor.m
//  CCDebugTool
//
//  Created by CC on 2019/11/18.
//  Copyright © 2019 CC. All rights reserved.
//

#import "CCOperateMonitor.h"

#define operatePlistName @"CCOperate.plist"
#define operateWebPlistName @"CCWebOperate.plist"

#define kOperateLog [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"CCLog"]

@interface CCOperateMonitor ()

@property (nonatomic, copy) NSString *saveOperatePath;
@property (nonatomic, copy) NSString *saveWebOperatePath;

@property (nonatomic, strong) NSMutableArray *appPlist;
@property (nonatomic, strong) NSMutableArray *webPlist;

@end

@implementation CCOperateMonitor

+ (instancetype)manager
{
    static CCOperateMonitor *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CCOperateMonitor new];
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
    if (![[NSFileManager defaultManager] fileExistsAtPath:kOperateLog]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:kOperateLog
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:[kOperateLog stringByAppendingPathComponent:operatePlistName]])
        _appPlist = [[NSMutableArray arrayWithContentsOfFile:[kOperateLog stringByAppendingPathComponent:operatePlistName]] mutableCopy];
    else
        _appPlist = [NSMutableArray new];


    NSString *logfileName = [@"App - " stringByAppendingString:[[CCOperateMonitor dateToString:[NSDate date] formatter:@"yyyyMMddHHmmss"] stringByAppendingString:@".log"]];
    [_appPlist insertObject:logfileName atIndex:0];
    [_appPlist writeToFile:[kOperateLog stringByAppendingPathComponent:operatePlistName] atomically:YES];

    _saveOperatePath = [kOperateLog stringByAppendingPathComponent:logfileName];
    [[NSFileManager defaultManager] createFileAtPath:_saveOperatePath contents:nil attributes:nil];
}

- (void)initWeb
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:kOperateLog]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:kOperateLog
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:[kOperateLog stringByAppendingPathComponent:operateWebPlistName]])
        _webPlist = [[NSMutableArray arrayWithContentsOfFile:[kOperateLog stringByAppendingPathComponent:operateWebPlistName]] mutableCopy];
    else
        _webPlist = [NSMutableArray new];


    NSString *logfileName = [@"Web - " stringByAppendingString:[[CCOperateMonitor dateToString:[NSDate date] formatter:@"yyyyMMddHHmmss"] stringByAppendingString:@".log"]];
    [_webPlist insertObject:logfileName atIndex:0];
    [_webPlist writeToFile:[kOperateLog stringByAppendingPathComponent:operateWebPlistName] atomically:YES];

    _saveWebOperatePath = [kOperateLog stringByAppendingPathComponent:logfileName];
    [[NSFileManager defaultManager] createFileAtPath:_saveWebOperatePath contents:nil attributes:nil];
}

- (void)webOperateEnd
{
    if (_webCurrentURL)
        [self webOperateLogWrite:[NSString stringWithFormat:@"%@ - onbeforeunload", _webCurrentURL]];
}

/** 写入日志 **/
- (void)appOperateLogWrite:(NSString *)log
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:self.saveOperatePath];
    [fileHandle seekToEndOfFile];

    NSString *logTime = [[CCOperateMonitor dateToString:[NSDate date] formatter:@"yyyy-MM-dd HH:mm:ss"] stringByAppendingString:@"\n"];
    log = [[logTime stringByAppendingString:log] stringByAppendingString:@"\n\n"];
    [fileHandle writeData:[log dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle closeFile];
}

/** 写入日志 **/
- (void)webOperateLogWrite:(NSString *)log
{
    if (!_saveWebOperatePath)
        [self initWeb];

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:self.saveWebOperatePath];
    [fileHandle seekToEndOfFile];

    NSString *logTime = [[CCOperateMonitor dateToString:[NSDate date] formatter:@"yyyy-MM-dd HH:mm:ss"] stringByAppendingString:@"\n"];
    log = [[logTime stringByAppendingString:log] stringByAppendingString:@"\n\n"];
    [fileHandle writeData:[log dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle closeFile];
}

/** 获取日志信息 **/
+ (NSArray *)obtainLogs
{
    NSMutableArray *dataArray = [NSMutableArray array];
    [dataArray addObjectsFromArray:[CCOperateMonitor obtainOperates:operatePlistName]];
    [dataArray addObjectsFromArray:[CCOperateMonitor obtainOperates:operateWebPlistName]];

    NSArray *dataArr = [dataArray sortedArrayWithOptions:NSSortStable
                                         usingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        NSString *obj1FileName = [[obj1 objectForKey:@"fileName"] stringByReplacingOccurrencesOfString:@"App - " withString:@""];
        obj1FileName = [obj1FileName stringByReplacingOccurrencesOfString:@"Web - " withString:@""];

        NSString *obj2FileName = [[obj2 objectForKey:@"fileName"] stringByReplacingOccurrencesOfString:@"App - " withString:@""];
        obj2FileName = [obj2FileName stringByReplacingOccurrencesOfString:@"Web - " withString:@""];

        NSComparisonResult result = [obj1FileName localizedStandardCompare:obj2FileName];
        return result == NSOrderedAscending;
    }];

    return dataArr;
}

+ (NSArray *)obtainOperates:(NSString *)plistName
{
    NSArray *appPlist = [[NSMutableArray arrayWithContentsOfFile:[kOperateLog stringByAppendingPathComponent:plistName]] mutableCopy];

    NSMutableArray *operateArray = [NSMutableArray array];
    for (NSString *key in appPlist) {
        NSString *subPath = [kOperateLog stringByAppendingPathComponent:key];

        NSMutableDictionary *fileDic = [NSMutableDictionary dictionary];
        [fileDic setObject:key forKey:@"fileName"];
        [fileDic setObject:subPath forKey:@"filePath"];
        [operateArray addObject:fileDic];
    }
    [operateArray sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:NO] ]];
    return [operateArray copy];
}

@end
