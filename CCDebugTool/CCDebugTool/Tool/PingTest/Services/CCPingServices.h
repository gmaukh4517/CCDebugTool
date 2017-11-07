//
//  CCPingServices.h
//  CCDebugTool
//
//  Created by CC on 2017/11/3.
//  Copyright © 2017年 CC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "STSimplePing.h"

typedef NS_ENUM(NSInteger, CCPingStatus) {
    CCPingStatusDidStart,
    CCPingStatusDidFailToSendPacket,
    CCPingStatusDidReceivePacket,
    CCPingStatusDidReceiveUnexpectedPacket,
    CCPingStatusDidTimeout,
    CCPingStatusError,
    CCPingStatusFinished,
};

@interface CCPingItem : NSObject

@property(nonatomic) NSString *originalAddress;
@property(nonatomic, copy) NSString *IPAddress;

@property(nonatomic) NSUInteger dateBytesLength;
@property(nonatomic) double     timeMilliseconds;
@property(nonatomic) NSInteger  timeToLive;
@property(nonatomic) NSInteger  ICMPSequence;

@property(nonatomic) CCPingStatus status;

+ (NSString *)statisticsWithPingItems:(NSArray *)pingItems;

@end


@interface CCPingServices : NSObject

/** 超时时间, 默认 500ms **/
@property(nonatomic) double timeoutMilliseconds;

+ (CCPingServices *)startPingAddress:(NSString *)address
                      callbackHandler:(void(^)(CCPingItem *pingItem, NSArray *pingItems))handler;

@property(nonatomic) NSInteger  maximumPingTimes;

- (void)cancel;

@end
