//
//  CCNetworkRecorder.m
//  CCDebugTool
//
//  Created by CC on 2017/11/10.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCNetworkRecorder.h"
#import "CCNetworkTransaction.h"
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>


NSString *const kCCNetworkRecorderNewTransactionNotification = @"kCCNetworkRecorderNewTransactionNotification";
NSString *const kCCNetworkRecorderTransactionUpdatedNotification = @"kCCNetworkRecorderTransactionUpdatedNotification";
NSString *const kCCNetworkRecorderUserInfoTransactionKey = @"transaction";
NSString *const kCCNetworkRecorderTransactionsClearedNotification = @"kCCNetworkRecorderTransactionsClearedNotification";

@interface CCNetworkRecorder ()

@property (nonatomic, strong) NSMutableArray *orderedTransactions;
@property (nonatomic, strong) NSMutableDictionary *networkTransactionsForRequestIdentifiers;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation CCNetworkRecorder

+ (instancetype)defaultRecorder
{
    static CCNetworkRecorder *defaultRecorder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultRecorder = [[[self class] alloc] init];
    });
    return defaultRecorder;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.orderedTransactions = [NSMutableArray array];
        self.networkTransactionsForRequestIdentifiers = [NSMutableDictionary dictionary];

        // 串行队列使用，因为我们使用非线程安全的可变对象。
        self.queue = dispatch_queue_create("com.cc.CCNetworkRecorder", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark -
#pragma mark :. Public Data Access

- (NSArray *)networkTransactions
{
    __block NSArray *transactions = nil;
    dispatch_sync(self.queue, ^{
        transactions = [self.orderedTransactions copy];
    });
    return transactions;
}

- (void)clearRecordedActivity
{
    dispatch_async(self.queue, ^{
        [self.orderedTransactions removeAllObjects];
        [self.networkTransactionsForRequestIdentifiers removeAllObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kCCNetworkRecorderTransactionsClearedNotification object:self];
        });
    });
}

#pragma mark -
#pragma mark :. data handle

+ (NSString *)dataToJson:(id)data
{
    NSString *prettyString = nil;
    if ([data isKindOfClass:[NSDictionary class]]) {
        prettyString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:NULL] encoding:NSUTF8StringEncoding];
    } else if ([data isKindOfClass:[NSData class]]) {
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        if ([NSJSONSerialization isValidJSONObject:jsonObject]) {
            prettyString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:NULL] encoding:NSUTF8StringEncoding];
        } else {
            prettyString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }

    if (prettyString)
        prettyString = [prettyString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];

    return prettyString;
}

+ (UIImage *)thumbnailedImageWithMaxPixelDimension:(NSInteger)dimension
                                     fromImageData:(NSData *)data
{
    UIImage *thumbnail = nil;
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, 0);
    if (imageSource) {
        NSDictionary *options = @{(__bridge id)kCGImageSourceCreateThumbnailWithTransform : @YES,
                                  (__bridge id)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                  (__bridge id)kCGImageSourceThumbnailMaxPixelSize : @(dimension) };

        CGImageRef scaledImageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
        if (scaledImageRef) {
            thumbnail = [UIImage imageWithCGImage:scaledImageRef];
            CFRelease(scaledImageRef);
        }
        CFRelease(imageSource);
    }
    return thumbnail;
}

#pragma mark - Network Events

- (void)recordRequestWillBeSentWithRequestID:(NSString *)requestID request:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    for (NSString *host in self.hostBlacklist) {
        if ([request.URL.host hasSuffix:host])
            return;
    }

    NSDate *startDate = [NSDate date];

    if (redirectResponse) {
        [self recordResponseReceivedWithRequestID:requestID response:redirectResponse];
        [self recordLoadingFinishedWithRequestID:requestID responseBody:nil];
    }

    dispatch_async(self.queue, ^{
        @try {
            CCNetworkTransaction *transaction = [[CCNetworkTransaction alloc] init];
            transaction.requestID = requestID;
            transaction.request = request;
            transaction.startTime = startDate;
            transaction.transactionState = CCNetworkTransactionStateFinished;
            transaction.url = transaction.request.URL;
            transaction.method = transaction.request.HTTPMethod;
            transaction.requestAllHeaderFields = transaction.request.allHTTPHeaderFields;
            transaction.showRequestAllHeaderFields = [CCNetworkRecorder dataToJson:transaction.request.allHTTPHeaderFields];
            [transaction cpmversopmCachePolicy:transaction.request.cachePolicy];
            @try {
                if (transaction.request.HTTPBody) {
                    transaction.requestBody = [CCNetworkRecorder dataToJson:transaction.request.HTTPBody];
                    transaction.requestDataSize = transaction.request.HTTPBody.length;
                }
            } @catch (NSException *exception) {
            } @finally {
            }

            [self.orderedTransactions insertObject:transaction atIndex:0];
            [self.networkTransactionsForRequestIdentifiers setObject:transaction forKey:requestID];
            transaction.transactionState = CCNetworkTransactionStateAwaitingResponse;

            [self postNewTransactionNotificationWithTransaction:transaction];
        } @catch (NSException *exception) {
            //捕获异常
        }
    });
}

- (void)recordResponseReceivedWithRequestID:(NSString *)requestID response:(NSURLResponse *)response
{
    NSDate *responseDate = [NSDate date];

    dispatch_async(self.queue, ^{
        CCNetworkTransaction *transaction = self.networkTransactionsForRequestIdentifiers[ requestID ];
        if (!transaction)
            return;

        transaction.response = response;
        transaction.transactionState = CCNetworkTransactionStateReceivingData;
        transaction.latency = -[transaction.startTime timeIntervalSinceDate:responseDate];

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordDataReceivedWithRequestID:(NSString *)requestID dataLength:(int64_t)dataLength
{
    dispatch_async(self.queue, ^{
        CCNetworkTransaction *transaction = self.networkTransactionsForRequestIdentifiers[ requestID ];
        if (!transaction) {
            return;
        }
        transaction.expectedContentLength += dataLength;

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordLoadingFinishedWithRequestID:(NSString *)requestID responseBody:(NSData *)responseBody
{
    NSDate *finishedDate = [NSDate date];

    dispatch_async(self.queue, ^{
        @try {
            CCNetworkTransaction *transaction = self.networkTransactionsForRequestIdentifiers[ requestID ];
            if (!transaction) {
                return;
            }
            transaction.transactionState = CCNetworkTransactionStateFinished;
            transaction.totalDuration = -[transaction.startTime timeIntervalSinceDate:finishedDate];

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)transaction.response;
            transaction.statusCode = [NSString stringWithFormat:@"%d", (int)httpResponse.statusCode];

            NSString *mineType = transaction.response.MIMEType;
            if ([transaction.response textEncodingName])
                mineType = [NSString stringWithFormat:@"%@; charset=%@", transaction.response.MIMEType, [transaction.response textEncodingName]];

            transaction.mineType = mineType;
            transaction.responseAllHeaderFields = httpResponse.allHeaderFields;
            transaction.showResponseAllHeaderFields = [CCNetworkRecorder dataToJson:httpResponse.allHeaderFields];
            if (responseBody) {
                transaction.responseBody = [CCNetworkRecorder dataToJson:responseBody];
                transaction.responseData = responseBody;
            }
            transaction.isImage = NO;
            transaction.expectedContentLength += transaction.response.expectedContentLength;

            NSString *mimeType = transaction.response.MIMEType;
            if ([mimeType hasPrefix:@"image/"] && [responseBody length] > 0) {
                transaction.isImage = YES;
                // Thumbnail image previews on a separate background queue
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSInteger maxPixelDimension = [[UIScreen mainScreen] scale] * 32.0;
                    //                transaction.responseThumbnail = [CCNetworkRecorder thumbnailedImageWithMaxPixelDimension:maxPixelDimension fromImageData:responseBody];
                    [self postUpdateNotificationForTransaction:transaction];
                });
            } else if ([mimeType isEqual:@"application/json"]) {
                //            transaction.responseThumbnail = [FLEXResources jsonIcon];
            } else if ([mimeType isEqual:@"text/plain"]) {
                //            transaction.responseThumbnail = [FLEXResources textPlainIcon];
            } else if ([mimeType isEqual:@"text/html"]) {
                //            transaction.responseThumbnail = [FLEXResources htmlIcon];
            } else if ([mimeType isEqual:@"application/x-plist"]) {
                //            transaction.responseThumbnail = [FLEXResources plistIcon];
            } else if ([mimeType isEqual:@"application/octet-stream"] || [mimeType isEqual:@"application/binary"]) {
                //            transaction.responseThumbnail = [FLEXResources binaryIcon];
            } else if ([mimeType rangeOfString:@"javascript"].length > 0) {
                //            transaction.responseThumbnail = [FLEXResources jsIcon];
            } else if ([mimeType rangeOfString:@"xml"].length > 0) {
                //            transaction.responseThumbnail = [FLEXResources xmlIcon];
            } else if ([mimeType hasPrefix:@"audio"]) {
                //            transaction.responseThumbnail = [FLEXResources audioIcon];
            } else if ([mimeType hasPrefix:@"video"]) {
                //            transaction.responseThumbnail = [FLEXResources videoIcon];
            } else if ([mimeType hasPrefix:@"text"]) {
                //            transaction.responseThumbnail = [FLEXResources textIcon];
            }


            [self postUpdateNotificationForTransaction:transaction];
        } @catch (NSException *exception) {
        }
    });
}

- (void)recordLoadingFailedWithRequestID:(NSString *)requestID error:(NSError *)error
{
    dispatch_async(self.queue, ^{
        CCNetworkTransaction *transaction = self.networkTransactionsForRequestIdentifiers[ requestID ];
        if (!transaction) {
            return;
        }
        transaction.transactionState = CCNetworkTransactionStateFailed;
        transaction.totalDuration = -[transaction.startTime timeIntervalSinceNow];
        transaction.error = error;

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordMechanism:(NSString *)mechanism forRequestID:(NSString *)requestID
{
    dispatch_async(self.queue, ^{
        CCNetworkTransaction *transaction = self.networkTransactionsForRequestIdentifiers[ requestID ];
        if (!transaction)
            return;

        transaction.requestMechanism = mechanism;

        [self postUpdateNotificationForTransaction:transaction];
    });
}

#pragma mark Notification Posting

- (void)postNewTransactionNotificationWithTransaction:(CCNetworkTransaction *)transaction
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{kCCNetworkRecorderUserInfoTransactionKey : transaction};
        [[NSNotificationCenter defaultCenter] postNotificationName:kCCNetworkRecorderNewTransactionNotification object:self userInfo:userInfo];
    });
}

- (void)postUpdateNotificationForTransaction:(CCNetworkTransaction *)transaction
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{kCCNetworkRecorderUserInfoTransactionKey : transaction};
        [[NSNotificationCenter defaultCenter] postNotificationName:kCCNetworkRecorderTransactionUpdatedNotification object:self userInfo:userInfo];
    });
}

@end
