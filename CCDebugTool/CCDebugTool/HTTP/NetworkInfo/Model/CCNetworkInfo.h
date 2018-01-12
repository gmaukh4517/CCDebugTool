//
//  CCNetworkInfo.h
//  CCDebugTool
//
//  Created by CC on 2018/1/12.
//  Copyright © 2018年 CC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCNetworkinfoEntity : NSObject

@property (nonatomic, copy) NSString *readableInterface;
@property (nonatomic, copy) NSString *networkName;
@property (nonatomic, copy) NSString *externalIPAddress;
@property (nonatomic, copy) NSString *internalIPAddress;
@property (nonatomic, copy) NSString *netmask;
@property (nonatomic, copy) NSString *broadcastAddress;
@property (nonatomic, copy) NSString *routerAddress;

@end


@protocol CCNetworkInfoDelegate <NSObject>
@optional

- (void)networkStatusUpdated;
- (void)networkExternalIPAddressUpdated;
- (void)networkMaxBandwidthUpdated;
- (void)networkActiveConnectionsUpdated:(NSArray *)connections;
@end

@interface CCNetworkInfo : NSObject

@property (nonatomic, weak) id<CCNetworkInfoDelegate> delegate;

- (CCNetworkinfoEntity *)populateNetworkInfo;

@end
