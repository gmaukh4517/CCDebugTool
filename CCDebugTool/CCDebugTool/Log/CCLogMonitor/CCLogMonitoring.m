//
//  CCDebugLogHelper.m
//  CCDebugTool
//
//  Created by CC on 2017/11/16.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCLogMonitoring.h"

const int maxLogSize = 3; // 日志文件最大 3M

#define logPlistName @"CCCrashLog.plist"

#define kLogCatalog [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"CCLog"]

@interface CCLogMonitoring ()

@property (nonatomic, strong) NSMutableArray *logPlist;

@property (nonatomic,strong) dispatch_source_t sourt_t;

@end

@implementation CCLogMonitoring

+ (instancetype)manager
{
    static CCLogMonitoring *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CCLogMonitoring new];
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
    if (![[NSFileManager defaultManager] fileExistsAtPath:kLogCatalog]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:kLogCatalog
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }
   
    if ([[NSFileManager defaultManager] fileExistsAtPath:[kLogCatalog stringByAppendingPathComponent:logPlistName]])
        _logPlist = [[NSMutableArray arrayWithContentsOfFile:[kLogCatalog stringByAppendingPathComponent:logPlistName]] mutableCopy];
    else
        _logPlist = [NSMutableArray new];
}

-(NSString *)newLogFile
{
    NSString *logfileName = [[CCLogMonitoring dateToString:[NSDate date] formatter:@"yyyyMMddHHmmssSSS"] stringByAppendingString:@".log"];
    [_logPlist insertObject:logfileName atIndex:0];
    [_logPlist writeToFile:[kLogCatalog stringByAppendingPathComponent:logPlistName] atomically:YES];
    
    NSString *fliePath = [kLogCatalog stringByAppendingPathComponent:logfileName];
    [[NSFileManager defaultManager] createFileAtPath:fliePath contents:nil attributes:nil];
    return fliePath;
}

/** 写入日志 **/
-(void)logWrite:(NSString *)log
{
    NSString *saceCrashPath;
    if (_logPlist.count > 0) {
        saceCrashPath = [kLogCatalog stringByAppendingPathComponent:_logPlist.firstObject];
        
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:saceCrashPath error:nil];
        NSInteger fileSize = [[fileAttributes objectForKey:NSFileSize] integerValue];
        if (fileSize >= (maxLogSize * 1024 * 1024))
            saceCrashPath = [self newLogFile];
    }else{
        saceCrashPath = [self newLogFile];
    }
    
//    NSString *logDate = [log substringFromIndex:23];
//    NSString *logContent = [log substringToIndex:23];
//
//    NSMutableDictionary *logdic = [NSMutableDictionary dictionary];
//    [logdic setObject:logDate forKey:@"logDate"];
//    [logdic setObject:logContent forKey:@"logContent"];
    
    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:saceCrashPath];
    log = [log stringByAppendingString:@"\n"];
    [file seekToEndOfFile];
    NSData *logData = [log dataUsingEncoding:NSUTF8StringEncoding];
    [file writeData:logData];
}

/** 获取日志信息 **/
+ (NSArray *)obtainLogs
{
    NSArray *LogPlist = [[NSMutableArray arrayWithContentsOfFile:[kLogCatalog stringByAppendingPathComponent:logPlistName]] mutableCopy];
    
    NSMutableArray *logsArray = [NSMutableArray array];
    for (NSString *key in LogPlist) {
        NSString *subPath = [kLogCatalog stringByAppendingPathComponent:key];
        
        NSMutableDictionary *fileDic = [NSMutableDictionary dictionary];
        [fileDic setObject:key forKey:@"fileName"];
        [fileDic setObject:subPath forKey:@"filePath"];
        [logsArray addObject:fileDic];
    }
    [logsArray sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:NO]]];
    
    return [logsArray copy];
}

-(void)startMonitoring
{
    _sourt_t = [self startCapturingLogFrom:STDERR_FILENO];
}

/** 开启日志监控 **/
- (dispatch_source_t)startCapturingLogFrom:(int)fd  {
    int origianlFD = fd;
    int originalStdHandle = dup(fd);//save the original for reset proporse
    int fildes[2];
    pipe(fildes);  // [0] is read end of pipe while [1] is write end
    dup2(fildes[1], fd);  // Duplicate write end of pipe "onto" fd (this closes fd)
    close(fildes[1]);  // Close original write end of pipe
    fd = fildes[0];  // We can now monitor the read end of the pipe
    
    NSMutableData* data = [[NSMutableData alloc] init];
    fcntl(fd, F_SETFL, O_NONBLOCK);// set the reading of this file descriptor without delay
    __weak typeof(self) wkSelf = self;
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fd, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    
    int writeEnd = fildes[1];
    dispatch_source_set_cancel_handler(source, ^{
        close(writeEnd);
        dup2(originalStdHandle, origianlFD);//reset the original file descriptor
    });
    
    dispatch_source_set_event_handler(source, ^{
        @autoreleasepool {
            char buffer[1024 * 10];
            ssize_t size = read(fd, (void*)buffer, (size_t)(sizeof(buffer)));
            [data setLength:0];
            [data appendBytes:buffer length:size];
            NSString *aString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [wkSelf logWrite:aString];
            printf("%s",[aString UTF8String]); //print on STDOUT_FILENO，so that the log can still print on xcode console
        }
    });
    dispatch_resume(source);
    return source;
}

@end
