//
//  CCDebugHttpModel.m
//  CCDebugTool
//
//  Created by CC on 2017/11/9.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCNetworkTransaction.h"

@interface CCNetworkTransaction ()

@property (nonatomic, assign) unsigned long long requestDataTrafficValue;

@property (nonatomic, assign) unsigned long long responseDataTrafficValue;

@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *cookies;

@end

@implementation CCNetworkTransaction

- (NSString *)showStartTime
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [formatter stringFromDate:_startTime];
}

- (NSString *)showLatency
{
    return [self times:_latency];
}

- (NSString *)showTotalDuration
{
    return [self times:_totalDuration];
}

- (NSString *)times:(NSTimeInterval)interval
{
    NSString *string = @"0s";
    if (interval > 0.0) {
        if (interval < 1.0)
            string = [NSString stringWithFormat:@"%dms", (int)(interval * 1000)];
        else if (interval < 10.0)
            string = [NSString stringWithFormat:@"%.2fs", interval];
        else
            string = [NSString stringWithFormat:@"%.1fs", interval];
    }
    return string;
}

- (void)cpmversopmCachePolicy:(NSInteger)cachePolicy
{
    switch (cachePolicy) {
        case 0:
            self.requestCachePolicy = @"NSURLRequestUseProtocolCachePolicy";
            break;
        case 1:
            self.requestCachePolicy = @"NSURLRequestReloadIgnoringLocalCacheData";
            break;
        case 2:
            self.requestCachePolicy = @"NSURLRequestReturnCacheDataElseLoad";
            break;
        case 3:
            self.requestCachePolicy = @"NSURLRequestReturnCacheDataDontLoad";
            break;
        case 4:
            self.requestCachePolicy = @"NSURLRequestUseProtocolCachePolicy";
            break;
        case 5:
            self.requestCachePolicy = @"NSURLRequestReloadRevalidatingCacheData";
            break;
        default:
            self.requestCachePolicy = @"";
            break;
    }
}

+ (NSString *)readableStringFromTransactionState:(CCNetworkTransactionState)state
{
    NSString *readableString = nil;
    switch (state) {
        case CCNetworkTransactionStateUnstarted:
            readableString = @"Unstarted";
            break;

        case CCNetworkTransactionStateAwaitingResponse:
            readableString = @"Awaiting Response";
            break;

        case CCNetworkTransactionStateReceivingData:
            readableString = @"Receiving Data";
            break;

        case CCNetworkTransactionStateFinished:
            readableString = @"Finished";
            break;

        case CCNetworkTransactionStateFailed:
            readableString = @"Failed";
            break;
    }
    return readableString;
}

- (NSDictionary<NSString *, NSString *> *)cookies
{
    if (!_cookies) {
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        NSArray<NSHTTPCookie *> *cookies = [cookieStorage cookiesForURL:self.url];
        if (cookies.count) {
            _cookies = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
        }
    }
    return _cookies;
}


- (unsigned long long)requestDataTrafficValue
{
    if (!_requestDataTrafficValue) {
        unsigned long long headerTraffic = [self dataTrafficLength:self.showRequestAllHeaderFields] + [self dataTrafficLength:self.showResponseAllHeaderFields];
        unsigned long long bodyTraffic = [self byteLength:self.requestBody];
        unsigned long long lineTraffic = [self dataTrafficLength:[self simulationHTTPRequestLine]];
        _requestDataTrafficValue = headerTraffic + bodyTraffic + lineTraffic;
    }
    return _requestDataTrafficValue;
}

- (unsigned long long)responseDataTrafficValue
{
    if (!_responseDataTrafficValue) {
        unsigned long long headerTraffic = [self dataTrafficLength:self.showResponseAllHeaderFields];
              unsigned long long bodyTraffic = self.responseData.length;
              unsigned long long stateLineTraffic = [self dataTrafficLength:self.stateLine];
              _responseDataTrafficValue = headerTraffic + bodyTraffic + stateLineTraffic;
    }
    return _responseDataTrafficValue;
}

- (unsigned long long)dataTrafficLength:(NSString *)string
{
    if (string == nil || ![string isKindOfClass:[NSString class]] || string.length == 0) {
        return 0;
    }

    return [string dataUsingEncoding:NSUTF8StringEncoding].length ?: [self byteLength:string];
}

- (unsigned long long)byteLength:(NSString *)dataString
{
    if (dataString.length == 0) {
        return 0;
    }
    unsigned long long length = 0;
    char *p = (char *)[dataString cStringUsingEncoding:NSUnicodeStringEncoding];
    for (NSInteger i = 0; i < [dataString lengthOfBytesUsingEncoding:NSUnicodeStringEncoding]; i++) {
        if (*p) {
            p++;
            length++;
        } else {
            p++;
        }
    }
    return (length + 1) / 2;
}

- (NSString *)simulationHTTPRequestLine {
    return [NSString stringWithFormat:@"%@ %@ %@\n", self.method, self.url.path, @"HTTP/1.1"];
}

@end
