//
//  CCDebugHttpModel.h
//  CCDebugTool
//
//  Created by CC on 2017/11/9.
//  Copyright © 2017年 CC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>

typedef NS_ENUM(NSInteger, CCNetworkTransactionState) {
    CCNetworkTransactionStateUnstarted,
    CCNetworkTransactionStateAwaitingResponse,
    CCNetworkTransactionStateReceivingData,
    CCNetworkTransactionStateFinished,
    CCNetworkTransactionStateFailed
};

@interface CCNetworkTransaction : NSObject

@property (nonatomic, strong) NSString *requestID;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, assign) CCNetworkTransactionState transactionState;


@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) NSString *statusCode;
@property (nonatomic, strong) NSString *mineType;

@property (nonatomic, assign) NSTimeInterval latency;
@property (nonatomic, strong) NSString *showLatency;

@property (nonatomic, assign) NSTimeInterval totalDuration;
@property (nonatomic, strong) NSString *showTotalDuration;

@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSString *showStartTime;

@property (nonatomic, strong) NSString *requestCachePolicy;
@property (nonatomic, strong) NSDictionary *requestAllHeaderFields;
@property (nonatomic, strong) NSString *showRequestAllHeaderFields;
@property (nonatomic, strong) NSString *requestBody;
@property (nonatomic, assign) NSInteger requestDataSize;

@property (nonatomic, strong) NSDictionary *responseAllHeaderFields;
@property (nonatomic, strong) NSString *showResponseAllHeaderFields;
@property (nonatomic, strong) NSString *responseBody;
@property (nonatomic, strong) NSData *responseData;

@property (nonatomic, strong) NSString *requestMechanism;
@property (nonatomic, strong) NSError *error;

@property (nonatomic, copy) NSString *stateLine;

@property (nonatomic, assign) long long expectedContentLength;
@property (nonatomic, assign, readonly) unsigned long long requestDataTrafficValue;
@property (nonatomic, assign, readonly) unsigned long long responseDataTrafficValue;

@property (nonatomic, assign) BOOL isImage;

@property (nonatomic, strong) UIImage *responseThumbnail;

- (void)cpmversopmCachePolicy:(NSInteger)cachePolicy;

+ (NSString *)readableStringFromTransactionState:(CCNetworkTransactionState)state;

@end
