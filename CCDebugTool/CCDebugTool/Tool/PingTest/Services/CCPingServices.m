//
//  CCPingServices.m
//  CCDebugTool
//
//  Created by CC on 2017/11/3.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCPingServices.h"

@implementation CCPingItem

- (NSString *)description {
    switch (self.status) {
        case CCPingStatusDidStart:
            return [NSString stringWithFormat:@"PING %@ (%@): %ld data bytes",self.originalAddress, self.IPAddress, (long)self.dateBytesLength];
        case CCPingStatusDidReceivePacket:
            return [NSString stringWithFormat:@"%ld bytes from %@: icmp_seq=%ld ttl=%ld time=%.3f ms", (long)self.dateBytesLength, self.IPAddress, (long)self.ICMPSequence, (long)self.timeToLive, self.timeMilliseconds];
        case CCPingStatusDidTimeout:
            return [NSString stringWithFormat:@"Request timeout for icmp_seq %ld", (long)self.ICMPSequence];
        case CCPingStatusDidFailToSendPacket:
            return [NSString stringWithFormat:@"Fail to send packet to %@: icmp_seq=%ld", self.IPAddress, (long)self.ICMPSequence];
        case CCPingStatusDidReceiveUnexpectedPacket:
            return [NSString stringWithFormat:@"Receive unexpected packet from %@: icmp_seq=%ld", self.IPAddress, (long)self.ICMPSequence];
        case CCPingStatusError:
            return [NSString stringWithFormat:@"Can not ping to %@", self.originalAddress];
        default:
            break;
    }
    if (self.status == CCPingStatusDidReceivePacket) {
    }
    return super.description;
}

+ (NSString *)statisticsWithPingItems:(NSArray *)pingItems
{
    NSString *address = [pingItems.firstObject originalAddress];
    __block NSInteger receivedCount = 0, allCount = 0;
    [pingItems enumerateObjectsUsingBlock:^(CCPingItem *obj, NSUInteger idx, BOOL *stop) {
        if (obj.status != CCPingStatusFinished && obj.status != CCPingStatusError) {
            allCount ++;
            if (obj.status == CCPingStatusDidReceivePacket)
                receivedCount ++;
        }
    }];
    
    NSMutableString *description = [NSMutableString stringWithCapacity:50];
    [description appendFormat:@"--- %@ ping statistics ---\n", address];
    
    CGFloat lossPercent = (CGFloat)(allCount - receivedCount) / MAX(1.0, allCount) * 100;
    [description appendFormat:@"%ld packets transmitted, %ld packets received, %.1f%% packet loss\n", (long)allCount, (long)receivedCount, lossPercent];
    return [description stringByReplacingOccurrencesOfString:@".0%" withString:@"%"];
}
@end

@interface CCPingServices() <STSimplePingDelegate>

@property (nonatomic, assign) BOOL hasStarted;
@property (nonatomic, assign) BOOL isTimeout;
@property (nonatomic, assign) NSInteger repingTimes;
@property (nonatomic, assign) NSInteger sequenceNumber;
@property (nonatomic, strong) NSMutableArray *pingItems;

@property (nonatomic, copy)   NSString   *address;
@property (nonatomic, strong) STSimplePing *simplePing;

@property (nonatomic, strong)void(^callbackHandler)(CCPingItem *item, NSArray *pingItems);

@end

@implementation CCPingServices

+ (CCPingServices *)startPingAddress:(NSString *)address
                      callbackHandler:(void(^)(CCPingItem *item, NSArray *pingItems))handler {
    CCPingServices *services = [[CCPingServices alloc] initWithAddress:address];
    services.callbackHandler = handler;
    [services startPing];
    return services;
}

- (instancetype)initWithAddress:(NSString *)address {
    self = [super init];
    if (self) {
        self.timeoutMilliseconds = 500;
        self.maximumPingTimes = 100;
        self.address = address;
        self.simplePing = [[STSimplePing alloc] initWithHostName:address];
        self.simplePing.addressStyle = STSimplePingAddressStyleAny;
        self.simplePing.delegate = self;
        _pingItems = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

- (void)startPing
{
    _repingTimes = 0;
    _hasStarted = NO;
    [_pingItems removeAllObjects];
    [self.simplePing start];
}

- (void)reping
{
    [self.simplePing stop];
    [self.simplePing start];
}

- (void)_timeoutActionFired
{
    CCPingItem *pingItem = [[CCPingItem alloc] init];
    pingItem.ICMPSequence = _sequenceNumber;
    pingItem.originalAddress = self.address;
    pingItem.status = CCPingStatusDidTimeout;
    [self.simplePing stop];
    [self _handlePingItem:pingItem];
}

- (void)_handlePingItem:(CCPingItem *)pingItem {
    if (pingItem.status == CCPingStatusDidReceivePacket || pingItem.status == CCPingStatusDidTimeout)
        [_pingItems addObject:pingItem];
    
    if (_repingTimes < self.maximumPingTimes - 1) {
        if (self.callbackHandler)
            self.callbackHandler(pingItem, [_pingItems copy]);
        
        _repingTimes ++;
        NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(reping) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    } else {
        if (self.callbackHandler)
            self.callbackHandler(pingItem, [_pingItems copy]);
        
        [self cancel];
    }
}

- (void)cancel
{
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeoutActionFired) object:nil];
    [self.simplePing stop];
    CCPingItem *pingItem = [[CCPingItem alloc] init];
    pingItem.status = CCPingStatusFinished;
    [_pingItems addObject:pingItem];
    
    if (self.callbackHandler)
        self.callbackHandler(pingItem, [_pingItems copy]);
    
}

- (void)st_simplePing:(STSimplePing *)pinger didStartWithAddress:(NSData *)address
{
    NSData *packet = [pinger packetWithPingData:nil];
    if (!_hasStarted) {
        CCPingItem *pingItem = [[CCPingItem alloc] init];
        pingItem.IPAddress = pinger.IPAddress;
        pingItem.originalAddress = self.address;
        pingItem.dateBytesLength = packet.length - sizeof(STICMPHeader);
        pingItem.status = CCPingStatusDidStart;
        if (self.callbackHandler) {
            self.callbackHandler(pingItem, nil);
        }
        _hasStarted = YES;
    }
    [pinger sendPacket:packet];
    [self performSelector:@selector(_timeoutActionFired) withObject:nil afterDelay:self.timeoutMilliseconds / 1000.0];
}

- (void)st_simplePing:(STSimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
    _sequenceNumber = sequenceNumber;
}

- (void)st_simplePing:(STSimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error
{
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeoutActionFired) object:nil];
    _sequenceNumber = sequenceNumber;
    CCPingItem *pingItem = [[CCPingItem alloc] init];
    pingItem.ICMPSequence = _sequenceNumber;
    pingItem.originalAddress = self.address;
    pingItem.status = CCPingStatusDidFailToSendPacket;
    [self _handlePingItem:pingItem];
}

- (void)st_simplePing:(STSimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeoutActionFired) object:nil];
    CCPingItem *pingItem = [[CCPingItem alloc] init];
    pingItem.ICMPSequence = _sequenceNumber;
    pingItem.originalAddress = self.address;
    pingItem.status = CCPingStatusDidReceiveUnexpectedPacket;
}

- (void)st_simplePing:(STSimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet timeToLive:(NSInteger)timeToLive sequenceNumber:(uint16_t)sequenceNumber timeElapsed:(NSTimeInterval)timeElapsed
{
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeoutActionFired) object:nil];
    CCPingItem *pingItem = [[CCPingItem alloc] init];
    pingItem.IPAddress = pinger.IPAddress;
    pingItem.dateBytesLength = packet.length;
    pingItem.timeToLive = timeToLive;
    pingItem.timeMilliseconds = timeElapsed * 1000;
    pingItem.ICMPSequence = sequenceNumber;
    pingItem.originalAddress = self.address;
    pingItem.status = CCPingStatusDidReceivePacket;
    [self _handlePingItem:pingItem];
}

- (void)st_simplePing:(STSimplePing *)pinger didFailWithError:(NSError *)error
{
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeoutActionFired) object:nil];
    [self.simplePing stop];
    
    CCPingItem *errorPingItem = [[CCPingItem alloc] init];
    errorPingItem.originalAddress = self.address;
    errorPingItem.status = CCPingStatusError;
    if (self.callbackHandler)
        self.callbackHandler(errorPingItem, [_pingItems copy]);
    
    CCPingItem *pingItem = [[CCPingItem alloc] init];
    pingItem.originalAddress = self.address;
    pingItem.IPAddress = pinger.IPAddress ?: pinger.hostName;
    [_pingItems addObject:pingItem];
    pingItem.status = CCPingStatusFinished;
    if (self.callbackHandler) {
        self.callbackHandler(pingItem, [_pingItems copy]);
    }
}

@end
