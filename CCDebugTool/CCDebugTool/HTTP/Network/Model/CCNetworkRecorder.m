//
//  CCNetworkRecorder.m
//  CCDebugTool
//
//  Created by CC on 2017/11/10.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCNetworkRecorder.h"
#import "CCNetworkResources.h"
#import "CCNetworkTransaction.h"
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/runtime.h>

NSString *const kCCNetworkRecorderNewTransactionNotification = @"kCCNetworkRecorderNewTransactionNotification";
NSString *const kCCNetworkRecorderTransactionUpdatedNotification = @"kCCNetworkRecorderTransactionUpdatedNotification";
NSString *const kCCNetworkRecorderUserInfoTransactionKey = @"transaction";
NSString *const kCCNetworkRecorderTransactionsClearedNotification = @"kCCNetworkRecorderTransactionsClearedNotification";

typedef CFHTTPMessageRef (*CCHTTPURLResponseGetHTTPProtocol)(CFURLRef response);

@interface CCNetworkRecorder ()

@property (nonatomic, strong) NSMutableArray<CCNetworkTransaction *> *orderedTransactions;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CCNetworkTransaction *> *networkTransactionsForRequestIdentifiers;
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
            if (!prettyString)
                prettyString = [[NSString alloc] initWithData:[CCNetworkRecorder cleanUTF8:data] encoding:NSUTF8StringEncoding];
        }
    }

    if (prettyString)
        prettyString = [prettyString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];

    return prettyString;
}

+ (NSData *)cleanUTF8:(NSData *)data
{
    //保存结果
    NSMutableData *resData = [[NSMutableData alloc] initWithCapacity:data.length];
    NSData *replacement = [@"�" dataUsingEncoding:NSUTF8StringEncoding];
    uint64_t index = 0;
    const uint8_t *bytes = data.bytes;
    long dataLength = (long)data.length;

    while (index < dataLength) {
        uint8_t len = 0;
        uint8_t firstChar = bytes[ index ];

        // 1个字节
        if ((firstChar & 0x80) == 0 && (firstChar == 0x09 || firstChar == 0x0A || firstChar == 0x0D || (0x20 <= firstChar && firstChar <= 0x7E))) {
            len = 1;
        } else if ((firstChar & 0xE0) == 0xC0 && (0xC2 <= firstChar && firstChar <= 0xDF)) { // 2字节
            if (index + 1 < dataLength) {
                uint8_t secondChar = bytes[ index + 1 ];
                if (0x80 <= secondChar && secondChar <= 0xBF) {
                    len = 2;
                }
            }
        } else if ((firstChar & 0xF0) == 0xE0) { // 3字节
            if (index + 2 < dataLength) {
                uint8_t secondChar = bytes[ index + 1 ];
                uint8_t thirdChar = bytes[ index + 2 ];

                if (firstChar == 0xE0 && (0xA0 <= secondChar && secondChar <= 0xBF) && (0x80 <= thirdChar && thirdChar <= 0xBF)) {
                    len = 3;
                } else if (((0xE1 <= firstChar && firstChar <= 0xEC) || firstChar == 0xEE || firstChar == 0xEF) && (0x80 <= secondChar && secondChar <= 0xBF) && (0x80 <= thirdChar && thirdChar <= 0xBF)) {
                    len = 3;
                } else if (firstChar == 0xED && (0x80 <= secondChar && secondChar <= 0x9F) && (0x80 <= thirdChar && thirdChar <= 0xBF)) {
                    len = 3;
                }
            }
        } else if ((firstChar & 0xF8) == 0xF0) { // 4字节
            if (index + 3 < dataLength) {
                uint8_t secondChar = bytes[ index + 1 ];
                uint8_t thirdChar = bytes[ index + 2 ];
                uint8_t fourthChar = bytes[ index + 3 ];

                if (firstChar == 0xF0) {
                    if ((0x90 <= secondChar & secondChar <= 0xBF) && (0x80 <= thirdChar && thirdChar <= 0xBF) && (0x80 <= fourthChar && fourthChar <= 0xBF)) {
                        len = 4;
                    }
                } else if ((0xF1 <= firstChar && firstChar <= 0xF3)) {
                    if ((0x80 <= secondChar && secondChar <= 0xBF) && (0x80 <= thirdChar && thirdChar <= 0xBF) && (0x80 <= fourthChar && fourthChar <= 0xBF)) {
                        len = 4;
                    }
                } else if (firstChar == 0xF3) {
                    if ((0x80 <= secondChar && secondChar <= 0x8F) && (0x80 <= thirdChar && thirdChar <= 0xBF) && (0x80 <= fourthChar && fourthChar <= 0xBF)) {
                        len = 4;
                    }
                }
            }
        } else if ((firstChar & 0xFC) == 0xF8) { // 5个字节
            len = 0;
        } else if ((firstChar & 0xFE) == 0xFC) { // 6个字节
            len = 0;
        }

        if (len == 0) {
            index++;
            [resData appendData:replacement];
        } else {
            [resData appendBytes:bytes + index length:len];
            index += len;
        }
    }

    return resData;
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
            transaction.requestAllHeaderFields = transaction.request.allHTTPHeaderFields ?: @{};
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

            NSString *httpResponseString = nil;
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)transaction.response;
            transaction.stateLine = [self stateLine:httpResponse];
            NSString *statusCodeDescription = nil;
            if (httpResponse.statusCode == 200) {
                // Prefer OK to the default "no error"
                statusCodeDescription = @"OK";
            } else {
                statusCodeDescription = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
            }
            httpResponseString = [NSString stringWithFormat:@"%ld %@", (long)httpResponse.statusCode, statusCodeDescription];
            transaction.statusCode = httpResponseString;

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
                    transaction.responseThumbnail = [CCNetworkRecorder thumbnailedImageWithMaxPixelDimension:maxPixelDimension fromImageData:responseBody];
                    [self postUpdateNotificationForTransaction:transaction];
                });
            } else if ([mimeType isEqual:@"application/json"]) {
                transaction.responseThumbnail = [CCNetworkResources jsonIcon];
            } else if ([mimeType isEqual:@"text/plain"]) {
                transaction.responseThumbnail = [CCNetworkResources textPlainIcon];
            } else if ([mimeType isEqual:@"text/html"]) {
                transaction.responseThumbnail = [CCNetworkResources htmlIcon];
            } else if ([mimeType isEqual:@"application/x-plist"]) {
                transaction.responseThumbnail = [CCNetworkResources plistIcon];
            } else if ([mimeType isEqual:@"application/octet-stream"] || [mimeType isEqual:@"application/binary"]) {
                transaction.responseThumbnail = [CCNetworkResources binaryIcon];
            } else if ([mimeType rangeOfString:@"javascript"].length > 0) {
                transaction.responseThumbnail = [CCNetworkResources jsIcon];
            } else if ([mimeType rangeOfString:@"xml"].length > 0) {
                transaction.responseThumbnail = [CCNetworkResources xmlIcon];
            } else if ([mimeType hasPrefix:@"audio"]) {
                transaction.responseThumbnail = [CCNetworkResources audioIcon];
            } else if ([mimeType hasPrefix:@"video"]) {
                transaction.responseThumbnail = [CCNetworkResources videoIcon];
            } else if ([mimeType hasPrefix:@"text"]) {
                transaction.responseThumbnail = [CCNetworkResources textIcon];
            }
            
            if (httpResponse.statusCode != 200 && !transaction.responseThumbnail){
                transaction.responseThumbnail = [CCNetworkResources errorIcon];
            }

            [self postUpdateNotificationForTransaction:transaction];
        } @catch (NSException *exception) {
        }
    });
}

- (NSString *)stateLine:(NSHTTPURLResponse *)response
{
    NSString *stateLine = nil;

    NSString *functionName = @"CFURLResponseGetHTTPResponse";
    CCHTTPURLResponseGetHTTPProtocol getMessage = dlsym(RTLD_DEFAULT, [functionName UTF8String]);
    SEL selector = NSSelectorFromString(@"_CFURLResponse");
    if ([self respondsToSelector:selector] && NULL != getMessage) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        CFTypeRef cfResponse = CFBridgingRetain([self performSelector:selector]);
#pragma clang diagnostic pop
        if (NULL != cfResponse) {
            CFHTTPMessageRef messageRef = getMessage(cfResponse);
            if (NULL != messageRef) {
                CFStringRef stateLineRef = CFHTTPMessageCopyResponseStatusLine(messageRef);
                if (NULL != stateLineRef) {
                    stateLine = (__bridge NSString *)stateLineRef;
                    CFRelease(stateLineRef);
                }
            }
            CFRelease(cfResponse);
        }
    }
    return stateLine;
}

- (void)recordLoadingFailedWithRequestID:(NSString *)requestID error:(NSError *)error
{
    dispatch_async(self.queue, ^{
        CCNetworkTransaction *transaction = self.networkTransactionsForRequestIdentifiers[ requestID ];
        if (!transaction) {
            return;
        }
        
        transaction.responseThumbnail = [CCNetworkResources errorIcon];
        transaction.transactionState = CCNetworkTransactionStateFailed;
        transaction.totalDuration = -[transaction.startTime timeIntervalSinceNow];
        transaction.error = error;
        transaction.statusCode = [NSString stringWithFormat:@"%ld %@", (long)error.code, error.localizedDescription];
        
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
