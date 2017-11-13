//
//  CCDebugHttpModel.m
//  CCDebugTool
//
//  Created by CC on 2017/11/9.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCNetworkTransaction.h"

@implementation CCNetworkTransaction

-(NSString *)showStartTime
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [formatter stringFromDate:_startTime];
}

-(NSString *)showLatency
{
    return [self times:_latency];
}

- (NSString *)showTotalDuration
{
    return [self times:_totalDuration];
}

-(NSString *)times:(NSTimeInterval)interval
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

@end
