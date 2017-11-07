//
//  SpeedTestManager.h
//  CCDebugTool
//
//  Created by CC on 2017/11/6.
//  Copyright © 2017年 CC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCSpeedTestManager : NSObject

@property (nonatomic, copy) void(^speedBlock)(NSInteger speed);

@property (nonatomic, copy) void(^finishBlock)(NSInteger finishSpee);

-(void)startDownLoad;

-(void)startUpLoad;

+(NSString *)formattedFileSize:(NSInteger)size
                          unit:(NSString **)unit;

+ (NSString *)formatBandWidth:(NSInteger)size
                         unit:(NSString **)unit;

+ (NSString *)getWifiName;
@end
