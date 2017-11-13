//
//  CCNetwork.m
//  CCDebugTool
//
//  Created by CC on 2017/11/9.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCNetwork.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

@interface CCNetwork()

@end

@implementation CCNetwork

/** 网络状态 **/
+ (NSString *)networkState
{
    NSString *networkState;
    NSString *info = [CTTelephonyNetworkInfo new].currentRadioAccessTechnology;
    if ([info isEqualToString:CTRadioAccessTechnologyGPRS]){
        networkState = @"GPRS";
    } else if ([info isEqualToString:CTRadioAccessTechnologyEdge]){
        networkState = @"E";
    } else if ([info isEqualToString:CTRadioAccessTechnologyCDMA1x]){
        networkState = @"2G";
    } else if ([info isEqualToString:CTRadioAccessTechnologyWCDMA] ||
             [info isEqualToString:CTRadioAccessTechnologyHSDPA] ||
             [info isEqualToString:CTRadioAccessTechnologyHSUPA] ||
             [info isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0] ||
             [info isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA] ||
             [info isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB] ||
             [info isEqualToString:CTRadioAccessTechnologyeHRPD]){
        networkState =  @"3G";
    } else if ([info isEqualToString:CTRadioAccessTechnologyLTE]){
        networkState = @"4G";
    } else{
        networkState = @"无网络";
    }
    return networkState;
}

/** 运行商名称 **/
+(NSString *)carrierName
{
    return [CTTelephonyNetworkInfo new].subscriberCellularProvider.carrierName;
}

@end
