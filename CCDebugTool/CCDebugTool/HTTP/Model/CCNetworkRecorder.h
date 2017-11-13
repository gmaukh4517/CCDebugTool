//
//  CCNetworkRecorder.h
//  CCDebugTool
//
//  Created by CC on 2017/11/10.
//  Copyright © 2017年 CC. All rights reserved.
//

#import <Foundation/Foundation.h>

// Notifications posted when the record is updated
extern NSString *const kCCNetworkRecorderNewTransactionNotification;
extern NSString *const kCCNetworkRecorderTransactionUpdatedNotification;
extern NSString *const kCCNetworkRecorderUserInfoTransactionKey;
extern NSString *const kCCNetworkRecorderTransactionsClearedNotification;

@interface CCNetworkRecorder : NSObject

+ (instancetype)defaultRecorder;

@property (nonatomic, copy) NSArray<NSString *> *hostBlacklist;

/** 获取最新数据 **/
- (NSArray *)networkTransactions;

/** 清空所有数据 **/
- (void)clearRecordedActivity;

/** 当应用程序即将发送HTTP请求时调用。 **/
- (void)recordRequestWillBeSentWithRequestID:(NSString *)requestID request:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;

/** 当HTTP响应可用时调用。 **/
- (void)recordResponseReceivedWithRequestID:(NSString *)requestID response:(NSURLResponse *)response;

/** 通过网络接收数据块时调用。 **/
- (void)recordDataReceivedWithRequestID:(NSString *)requestID dataLength:(int64_t)dataLength;

/** 当HTTP请求完成加载时调用。 **/
- (void)recordLoadingFinishedWithRequestID:(NSString *)requestID responseBody:(NSData *)responseBody;

/** 当HTTP请求失败时调用。 **/
- (void)recordLoadingFailedWithRequestID:(NSString *)requestID error:(NSError *)error;

/**
 呼叫设置请求机制后随时recordrequestwillbesent…被称为。
 该字符串可以设置为用于生成请求的API的任何有用信息。
 **/
- (void)recordMechanism:(NSString *)mechanism forRequestID:(NSString *)requestID;

+ (NSString *)dataToJson:(id)data;

@end
