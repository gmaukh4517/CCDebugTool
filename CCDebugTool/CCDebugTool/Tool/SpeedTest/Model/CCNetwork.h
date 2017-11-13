//
//  CCNetwork.h
//  CCDebugTool
//
//  Created by CC on 2017/11/9.
//  Copyright © 2017年 CC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCNetwork : NSObject

/** 网络状态 **/
+ (NSString *)networkState;

/** 运行商名称 **/
+(NSString *)carrierName;

@end
