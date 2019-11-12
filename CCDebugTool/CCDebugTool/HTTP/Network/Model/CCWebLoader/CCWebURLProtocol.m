//
//  CCWebURLProtocol.m
//  CCDebugTool
//
//  Created by CC on 2019/10/23.
//  Copyright © 2019 CC. All rights reserved.
//

#import "CCWebURLProtocol.h"
#import <objc/runtime.h>
#import <WebKit/WebKit.h>

static NSString *const kCCNSURLProtocolKey = @"KCCNSURLProtocolKey";

@interface CCWebURLProtocol ()

@property (nonatomic, assign) BOOL receivedResponse;
@property (nonatomic, assign) BOOL stoppedLoading;

@property (nonatomic, strong) NSURLSessionTask *requestHandlerTask;

@end

@implementation CCWebURLProtocol

+ (void)load
{
    [NSURLProtocol registerClass:self];
    [CCWebURLProtocol setEnableWKCustomProtocol:YES];
}

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task
{
    return [self canInitWithRequest:task.currentRequest];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
//    NSString *scheme = request.URL.scheme;
//    if (([scheme caseInsensitiveCompare:@"http"] == NSOrderedSame ||
//         [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame)) {
//        if ([NSURLProtocol propertyForKey:kCCNSURLProtocolKey inRequest:request])
//            return NO;
//        return YES;
//    }
    return NO;
}

- (void)startLoading
{
    NSThread *thread = [NSThread currentThread];
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:kCCNSURLProtocolKey inRequest:mutableReqeust];

    __weak id wself = self;
    self.requestHandlerTask = [[NSURLSession sharedSession] dataTaskWithRequest:mutableReqeust
                                                              completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        __strong CCWebURLProtocol *self = wself;
        [self performSelector:@selector(performBlock:)
                     onThread:thread
                   withObject:^{
            __strong CCWebURLProtocol *self = wself;
            if (response) {
                [self callbackRequestDidReceiveResponse:response];
            }
            if (error) {
                [self callbackRequestDidFailWithError:error];
            } else {
                [self callbackRequestDidLoadData:data];
                [self callbackRequestDidFinishLoading];
            }
        }
                waitUntilDone:NO];
    }];
    [self.requestHandlerTask resume];
}

- (void)performBlock:(dispatch_block_t)block
{
    if (block) {
        block();
    }
}

- (void)stopLoading
{
    self.stoppedLoading = YES;
    [self.requestHandlerTask cancel];
}

/// 保证 Response URL 跟请求时一致
- (NSURLResponse *)callbackResponseWithResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (id)response;
    if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        if (![httpResponse.URL isEqual:self.request.URL]) {
            httpResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:httpResponse.statusCode HTTPVersion:@"HTTP/1.1" headerFields:httpResponse.allHeaderFields];
        }
    }
    return httpResponse;
}

- (void)callbackRequestWasRedirectedToRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if (self.receivedResponse) {
        NSError *error = [NSError errorWithDomain:@"only return first received response !!" code:-999 userInfo:nil];
        NSAssert(NO, error.domain);
        return;
    }
    if (self.stoppedLoading) {
        return;
    }
    response = [self callbackResponseWithResponse:response];
    if (!response) {
        NSError *error = [NSError errorWithDomain:@"wasRedirectedToRequest redirectResponse not found !!" code:-999 userInfo:nil];
        [self callbackRequestDidFailWithError:error];
    } else {
        self.receivedResponse = YES;
        [[self class] removePropertyForKey:kCCNSURLProtocolKey inRequest:[request mutableCopy]];
        [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
}

- (void)callbackRequestDidReceiveResponse:(NSURLResponse *)response
{
    if (self.receivedResponse) {
        NSError *error = [NSError errorWithDomain:@"only return first received response !!" code:-999 userInfo:nil];
        NSAssert(NO, error.domain);
        return;
    }
    if (self.stoppedLoading) {
        return;
    }
    response = [self callbackResponseWithResponse:response];
    if (!response) {
        NSError *error = [NSError errorWithDomain:@"response not found !!" code:-999 userInfo:nil];
        NSLog(@"%@", error.domain);
    } else {
        self.receivedResponse = YES;
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    }
}

- (void)callbackRequestDidLoadData:(NSData *)data
{
    if (self.stoppedLoading) {
        return;
    }
    if (!self.receivedResponse) {
        NSError *error = [NSError errorWithDomain:@"didReceiveData to be scheduled before didReceiveResponse !!" code:-999 userInfo:nil];
        NSLog(@"%@", error.domain);
    } else if (data.length > 0) {
        [self.client URLProtocol:self didLoadData:data];
    }
}

- (void)callbackRequestDidFailWithError:(NSError *)error
{
    if (self.stoppedLoading) {
        return;
    }
    NSLog(@"%@", error.domain);
    [self.client URLProtocol:self didFailWithError:error];
}

- (void)callbackRequestDidFinishLoading
{
    if (self.stoppedLoading) {
        return;
    }
    if (!self.receivedResponse) {
        NSError *error = [NSError errorWithDomain:@"didFinishLoading to be scheduled before didReceiveResponse !!" code:-999 userInfo:nil];
        [self callbackRequestDidFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

@end

@implementation CCWebURLProtocol (WKCustomProtocol)

static BOOL kCCEnableWKCustomProtocol = NO;

+ (void)setEnableWKCustomProtocol:(BOOL)enableWKCustomProtocol
{
    kCCEnableWKCustomProtocol = enableWKCustomProtocol;
    id contextController = NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"WK", @"Browsing", @"ContextController"]);
    if (!contextController) {
        return;
    }
    SEL performSEL = nil;
    if (enableWKCustomProtocol) {
        performSEL = NSSelectorFromString([NSString stringWithFormat:@"%@%@", @"register", @"SchemeForCustomProtocol:"]);
    } else {
        performSEL = NSSelectorFromString([NSString stringWithFormat:@"%@%@", @"unregister", @"SchemeForCustomProtocol:"]);
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([contextController respondsToSelector:performSEL]) {
        [contextController performSelector:performSEL withObject:@"http"];
        [contextController performSelector:performSEL withObject:@"https"];
    }
#pragma clang diagnostic pop
}

+ (BOOL)enableWKCustomProtocol
{
    return kCCEnableWKCustomProtocol;
}

@end
