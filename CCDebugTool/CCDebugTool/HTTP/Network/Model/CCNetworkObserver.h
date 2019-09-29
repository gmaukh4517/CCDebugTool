//
//  CCNetworkObserver.h
//  CCDebugTool
//
//  Created by CC on 2017/11/10.
//  Copyright © 2017年 CC. All rights reserved.
//


#import <Foundation/Foundation.h>

extern NSString *const kCCNetworkObserverEnabledStateChangedNotification;

/// This class swizzles NSURLConnection and NSURLSession delegate methods to observe events in the URL loading system.
/// High level network events are sent to the default FLEXNetworkRecorder instance which maintains the request history and caches response bodies.
@interface CCNetworkObserver : NSObject

/// Swizzling occurs when the observer is enabled for the first time.
/// This reduces the impact of FLEX if network debugging is not desired.
/// NOTE: this setting persists between launches of the app.
+ (void)setEnabled:(BOOL)enabled;
+ (BOOL)isEnabled;

@end
