//
//  SpeedTestManager.m
//  CCDebugTool
//
//  Created by CC on 2017/11/6.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCSpeedTestManager.h"

#define urlString @"http://down.sandai.net/thunder7/Thunder_dl_7.9.34.4908.exe"//30M

// 分隔符
#define kBoundary @"----WebKitFormBoundary3pVJSvbLhiFiCeZC"
// 换行 并且要转码
#define kNewline [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]
// URLString
#define kURLString @"http://120.25.226.186:32812/upload"

@interface CCSpeedTestManager () <NSURLSessionDelegate,NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, assign) NSInteger connectSize;
@property (nonatomic, assign) NSInteger speedSize;

@property (nonatomic, strong) NSTimer *speedTime;

/** 平均数 **/
@property (nonatomic, assign) NSInteger average;
@property (nonatomic, assign) NSInteger second;


@end

@implementation CCSpeedTestManager

- (instancetype)init
{
    if (self = [super init]) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        //设置请求超时为10秒钟
        config.timeoutIntervalForRequest = 10;
        //在蜂窝网络情况下是否继续请求（上传或下载）
        config.allowsCellularAccess = NO;
        
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

-(void)startDownLoad
{
    _speedTime = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(speedHandle) userInfo:nil repeats:YES];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask *dataTask = [_session dataTaskWithURL:url];
    [dataTask resume];
    [_speedTime fire];
    _second = 0;
}

-(void)startUpLoad
{
    _speedTime = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(speedHandle) userInfo:nil repeats:YES];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kURLString]];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", kBoundary] forHTTPHeaderField:@"Content-Type"];
    
    NSData *data = [self bodyData];
    request.HTTPBody = data;
    
    __weak typeof(self) wSelf = self;
    NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [wSelf finishMeasure];
    }];
    [uploadTask resume];
    [_speedTime fire];
    _second = 0;
}

-(NSData *)bodyData
{
    NSMutableData *fileData = [NSMutableData data];
    [fileData appendData:[[NSString stringWithFormat:@"--%@",kBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [fileData appendData:kNewline];// 换行
    [fileData appendData:[@"Content-Disposition: form-data; name=\"file\"; filename=\"speedTest.txt\"" dataUsingEncoding:NSUTF8StringEncoding]];
    [fileData appendData:kNewline];
    [fileData appendData:[@"Content-Type: text/plain" dataUsingEncoding:NSUTF8StringEncoding]];
    [fileData appendData:kNewline];
    [fileData appendData:kNewline];// 因为空了一行，所以需要再换行
    NSBundle *bundle =  [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"CCDebugTool" withExtension:@"bundle"]];
    NSData *speedTestData = [NSData dataWithContentsOfFile:[[bundle resourcePath] stringByAppendingPathComponent:@"speedTest.txt"]];
    [fileData appendData:speedTestData];
    
    // 继续拼接请求体信息字段
    [fileData appendData:kNewline];
    [fileData appendData:[[NSString stringWithFormat:@"--%@",kBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [fileData appendData:kNewline];
    [fileData appendData:[@"Content-Disposition: form-data; name=\"CCSpeedTest\"" dataUsingEncoding:NSUTF8StringEncoding]];
    [fileData appendData:kNewline];
    [fileData appendData:kNewline];// 因为空了一行，所以需要再换行
    
    [fileData appendData:[@"这里是非文件参数" dataUsingEncoding:NSUTF8StringEncoding]];
    [fileData appendData:kNewline];
    [fileData appendData:[[NSString stringWithFormat:@"--%@",kBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return fileData;
}

#pragma mark -
#pragma mark :. Block handle
-(void)speedHandle
{
    ++_second;
    if (_second == _average) {
        [self finishMeasure];
        return;
    }
    
    !_speedBlock?:_speedBlock(_speedSize);
    _speedSize = 0;
}

-(void)finishMeasure
{
    [_speedTime invalidate];
    _speedTime = nil;
    if (_second != 0) {
        float finishSpeed = _connectSize / _second;
        !_finishBlock?:_finishBlock(finishSpeed);
    }
    _connectSize = 0;
    _speedSize = 0;
}

#pragma mark -
#pragma mark :. NSURLSessionDelegate

/*
 bytesSent:本次上传的数据大小
 totalBytesSent:已经上传数据的总大小
 totalBytesExpectedToSend:文件的总大小
 */
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    _speedSize += bytesSent;
    _connectSize = totalBytesSent;
}

/*
 1.当接收到服务器响应的时候调用
 session：发送请求的session对象
 dataTask：根据NSURLSession创建的task任务
 response:服务器响应信息（响应头）
 completionHandler：通过该block回调，告诉服务器端是否接收返回的数据
 */
-(void)URLSession:(nonnull NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler
{
    self.average = round(dataTask.response.expectedContentLength / 1024 / 1024) / 2; //文件总大小 取得平均数
    !completionHandler?:completionHandler(NSURLSessionResponseAllow);
}

/*
 2.当接收到服务器返回的数据时调用
 该方法可能会被调用多次
 */
-(void)URLSession:(nonnull NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveData:(nonnull NSData *)data
{
    self.connectSize += data.length;
    self.speedSize += data.length;
}

/*
 3.当请求完成之后调用该方法
 不论是请求成功还是请求失败都调用该方法，如果请求失败，那么error对象有值，否则那么error对象为空
 */
-(void)URLSession:(nonnull NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    [self finishMeasure];
}

#pragma mark -
#pragma mark :. Function method

+(NSString *)formattedFileSize:(NSInteger)size
                          unit:(NSString **)unit
{
    NSString *formattedStr = nil;
    if (size > 0 && size < 1024)
        formattedStr = [NSString stringWithFormat:@"%zi", size], *unit = @"B";
    else if (size >= 1024 && size < pow(1024, 2))
        formattedStr = [NSString stringWithFormat:@"%.2f", (size / 1024.)], *unit = @"KB";
    else  if (size >= pow(1024, 2) && size < pow(1024, 3))
        formattedStr = [NSString stringWithFormat:@"%.2f", (size / pow(1024, 2))], *unit = @"MB";
    else if (size >= pow(1024, 3))
        formattedStr = [NSString stringWithFormat:@"%.2f", (size / pow(1024, 3))], *unit = @"GB";
    return formattedStr;
}

+ (NSString *)formatBandWidth:(NSInteger)size
                         unit:(NSString **)unit
{
    size *=8;
    
    NSString *formattedStr = nil;
    if (size == 0){
        formattedStr = NSLocalizedString(@"0",@"");
        
    }else if (size > 0 && size < 1024){
        formattedStr = [NSString stringWithFormat:@"%zi", size];
        *unit = @"B";
    }else if (size >= 1024 && size < pow(1024, 2)){
        int intsize = (int)(size / 1024);
        int model = size % 1024;
        if (model > 512)
            intsize += 1;
        
        formattedStr = [NSString stringWithFormat:@"%d",intsize];
        *unit = @"KB";
    }else if (size >= pow(1024, 2) && size < pow(1024, 3)){
        unsigned long long l = pow(1024, 2);
        int intsize = size / pow(1024, 2);
        int  model = (int)(size % l);
        if (model > l/2)
            intsize +=1;
        
        formattedStr = [NSString stringWithFormat:@"%d", intsize];
        *unit = @"MB";
    }else if (size >= pow(1024, 3)){
        int intsize = size / pow(1024, 3);
        formattedStr = [NSString stringWithFormat:@"%d", intsize];
        *unit = @"GB";
    }
    
    return formattedStr;
}


@end
