
//
//  CCNetworkInfo.m
//  CCDebugTool
//
//  Created by CC on 2018/1/12.
//  Copyright © 2018年 CC. All rights reserved.
//

#import "CCNetworkInfo.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import "getgateway.h"

@implementation CCNetworkinfoEntity

@end

@interface CCNetworkInfo ()

@property (nonatomic, strong) CCNetworkinfoEntity *networkInfo;

@property (nonatomic, assign) SCNetworkReachabilityRef reachability;
@property (nonatomic, strong) CTTelephonyNetworkInfo *telephonyNetworkInfo;
@property (nonatomic, copy) NSString *currentInterface;

@end

static NSString *kInterfaceWiFi = @"en0";
static NSString *kInterfaceWWAN = @"pdp_ip0";
static NSString *kInterfaceNone = @"";

@implementation CCNetworkInfo

- (id)init
{
    if (self = [super init]) {
        self.networkInfo = [[CCNetworkinfoEntity alloc] init];
        self.telephonyNetworkInfo = [CTTelephonyNetworkInfo new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentRadioTechnologyChangedCB) name:CTRadioAccessTechnologyDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    if (self.reachability)
        CFRelease(self.reachability);
}

- (CCNetworkinfoEntity *)populateNetworkInfo
{
    self.currentInterface = [self internetInterface];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.networkInfo.externalIPAddress = @"-";
        self.networkInfo.externalIPAddress = [self getExternalIPAddress];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[self delegate] respondsToSelector:@selector(networkStatusUpdated)])
                [[self delegate] networkStatusUpdated];
        });
    });

    self.networkInfo.readableInterface = [self readableCurrentInterface];
    self.networkInfo.networkName = [self getNetworkName:self.currentInterface];
    self.networkInfo.internalIPAddress = [self getInternalIPAddressOfInterface:self.currentInterface];
    self.networkInfo.netmask = [self getNetmaskOfInterface:self.currentInterface];
    self.networkInfo.broadcastAddress = [self getBroadcastAddressOfInterface:self.currentInterface];
    self.networkInfo.routerAddress = [self getRouterAddressOfInterface:self.currentInterface];

    return self.networkInfo;
}

#pragma mark -
#pragma mark :. 委托
- (void)reachabilityStatusChangedCB
{
    [self populateNetworkInfo];
    if ([[self delegate] respondsToSelector:@selector(networkStatusUpdated)]) {
        [[self delegate] networkStatusUpdated];
    }
}

- (void)currentRadioTechnologyChangedCB
{
    [self populateNetworkInfo];
    if ([[self delegate] respondsToSelector:@selector(networkStatusUpdated)]) {
        [[self delegate] networkStatusUpdated];
    }
}

#pragma mark -
#pragma mark :. 获取信息

- (NSString *)internetInterface
{
    if (!self.reachability)
        [self initReachability];

    if (!self.reachability)
        return kInterfaceNone;

    SCNetworkReachabilityFlags flags;
    if (!SCNetworkReachabilityGetFlags(self.reachability, &flags))
        return kInterfaceNone;

    if ((flags & kSCNetworkFlagsReachable) && (!(flags & kSCNetworkReachabilityFlagsIsWWAN)))
        return kInterfaceWiFi;

    if ((flags & kSCNetworkReachabilityFlagsReachable) && (flags & kSCNetworkReachabilityFlagsIsWWAN))
        return kInterfaceWWAN;

    return kInterfaceNone;
}

- (NSString *)readableCurrentInterface
{
    if ([self.currentInterface isEqualToString:kInterfaceWiFi]) {
        return @"WiFi";
    } else if ([self.currentInterface isEqualToString:kInterfaceWWAN]) {
        static NSString *interfaceFormat = @"Cellular (%@)";
        NSString *currentRadioTechnology = [[self telephonyNetworkInfo] currentRadioAccessTechnology];

        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyLTE]) return [NSString stringWithFormat:interfaceFormat, @"LTE"];
        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyEdge]) return [NSString stringWithFormat:interfaceFormat, @"Edge"];
        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyGPRS]) return [NSString stringWithFormat:interfaceFormat, @"GPRS"];
        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyCDMA1x] ||
            [currentRadioTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0] ||
            [currentRadioTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA] ||
            [currentRadioTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) return [NSString stringWithFormat:interfaceFormat, @"CDMA"];
        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyWCDMA]) return [NSString stringWithFormat:interfaceFormat, @"W-CDMA"];
        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyeHRPD]) return [NSString stringWithFormat:interfaceFormat, @"eHRPD"];
        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyHSDPA]) return [NSString stringWithFormat:interfaceFormat, @"HSDPA"];
        if ([currentRadioTechnology isEqualToString:CTRadioAccessTechnologyHSUPA]) return [NSString stringWithFormat:interfaceFormat, @"HSUPA"];

        return @"Cellular";
    } else {
        return @"Not Connected";
    }
}

- (BOOL)internetConnected
{
    if (!self.reachability)
        [self initReachability];

    if (!self.reachability)
        return NO;

    SCNetworkReachabilityFlags flags;
    if (!SCNetworkReachabilityGetFlags(self.reachability, &flags))
        return NO;

    BOOL isReachable = (flags & kSCNetworkReachabilityFlagsReachable);
    BOOL noConnectionRequired = !(flags & kSCNetworkReachabilityFlagsConnectionRequired);

    if (flags & kSCNetworkReachabilityFlagsIsWWAN)
        noConnectionRequired = YES;

    return ((isReachable && noConnectionRequired) ? YES : NO);
}

- (NSString *)getNetworkName:(NSString *)interface
{
    if ([self.currentInterface isEqualToString:kInterfaceWiFi]) {
        NSString *wifiName = @"-";
        CFArrayRef myArray = CNCopySupportedInterfaces();
        if (myArray != nil) {
            CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
            if (myDict != nil) {
                NSDictionary *dict = (NSDictionary *)CFBridgingRelease(myDict);
                wifiName = [dict valueForKey:@"SSID"];
            }
        }
        return wifiName;
    } else {
        return [CTTelephonyNetworkInfo new].subscriberCellularProvider.carrierName;
    }
}

- (NSString *)getExternalIPAddress
{
    NSString *ip = @"-";

    if (![self internetConnected]) {
        return ip;
    }

    NSURL *url = [NSURL URLWithString:@"http://www.dyndns.org/cgi-bin/check_ip.cgi"];
    if (!url)
        return ip;

    NSError *error = nil;
    NSString *ipHtml = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if (error)
        return ip;

    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"([0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3})"
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:&error];
    if (error)
        return ip;

    NSRange regexpRange = [regexp rangeOfFirstMatchInString:ipHtml options:NSMatchingReportCompletion range:NSMakeRange(0, ipHtml.length)];
    NSString *match = [ipHtml substringWithRange:regexpRange];

    if (match && match.length > 0)
        ip = [NSString stringWithString:match];

    return ip;
}

- (NSString *)getInternalIPAddressOfInterface:(NSString *)interface
{
    NSString *address = @"-";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;

    if (!interface || interface.length == 0)
        return address;

    if (getifaddrs(&interfaces) == 0) {
        temp_addr = interfaces;

        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:interface]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }

    freeifaddrs(interfaces);
    return address;
}

- (NSString *)getNetmaskOfInterface:(NSString *)interface
{
    NSString *netmask = @"-";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;

    if (!interface || interface.length == 0)
        return netmask;

    if (getifaddrs(&interfaces) == 0) {
        temp_addr = interfaces;

        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:interface]) {
                    netmask = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }

    freeifaddrs(interfaces);
    return netmask;
}

- (NSString *)getBroadcastAddressOfInterface:(NSString *)interface
{
    NSString *address = @"-";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;

    if (!interface || interface.length == 0)
        return address;

    if (getifaddrs(&interfaces) == 0) {
        temp_addr = interfaces;

        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:interface]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }

    freeifaddrs(interfaces);
    return address;
}

- (NSString *)getRouterAddressOfInterface:(NSString *)interface
{
    NSString *router = @"-";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;

    if (!interface || interface.length == 0)
        return router;

    if (getifaddrs(&interfaces) == 0) {
        temp_addr = interfaces;

        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:interface]) {
                    router = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }

    freeifaddrs(interfaces);
    in_addr_t i = inet_addr([router cStringUsingEncoding:NSUTF8StringEncoding]);
    in_addr_t *x = &i;

    unsigned char *s = getdefaultgateway(x);
    router = [NSString stringWithFormat:@"%d.%d.%d.%d", s[ 0 ], s[ 1 ], s[ 2 ], s[ 3 ]];
    free(s);

    return router;
}

#pragma mark -
#pragma mark :. 初始化对象
static void reachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
    assert(info != NULL);
    assert([(__bridge NSObject *)(info) isKindOfClass:[CCNetworkInfo class]]);

    CCNetworkInfo *networkCtrl = (__bridge CCNetworkInfo *)(info);
    [networkCtrl reachabilityStatusChangedCB];
}

- (void)initReachability
{
    if (!self.reachability) {
        struct sockaddr_in hostAddress;
        bzero(&hostAddress, sizeof(hostAddress));
        hostAddress.sin_len = sizeof(hostAddress);
        hostAddress.sin_family = AF_INET;

        self.reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&hostAddress);

        if (!self.reachability)
            return;

        BOOL result;
        SCNetworkReachabilityContext context = {0, (__bridge void *)self, NULL, NULL, NULL};

        result = SCNetworkReachabilitySetCallback(self.reachability, reachabilityCallback, &context);
        if (!result)
            return;

        result = SCNetworkReachabilityScheduleWithRunLoop(self.reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        if (!result)
            return;
    }
}
@end


