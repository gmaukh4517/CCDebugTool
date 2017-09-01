//
//  CCDebugHttpProtocol.m
//  CCKit
//
// Copyright (c) 2015 CC ( https://github.com/gmaukh4517/CCKit )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "CCDebugHttpProtocol.h"
#import "CCDebugHttpDataSource.h"
#import "CCDebugTool.h"
#import <UIKit/UIKit.h>

#define kCCProtocolKey @"CCHttpProtocolKey"

@interface CCDebugHttpProtocol () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) NSTimeInterval startTime;

@end

@implementation CCDebugHttpProtocol

#pragma mark - protocol
+ (void)load
{
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if (![request.URL.scheme isEqualToString:@"http"] &&
        ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    
    if ([NSURLProtocol propertyForKey:kCCProtocolKey inRequest:request]) {
        return NO;
    }
    
    if ([[CCDebugTool manager] arrOnlyHosts].count > 0) {
        NSString *url = [request.URL.absoluteString lowercaseString];
        for (NSString *_url in [CCDebugTool manager].arrOnlyHosts) {
            if ([url rangeOfString:[_url lowercaseString]].location != NSNotFound)
                return YES;
        }
        return NO;
    }
    
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:kCCProtocolKey inRequest:mutableReqeust];
    return [mutableReqeust copy];
}

- (void)startLoading
{
    self.data = [NSMutableData data];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.connection = [[NSURLConnection alloc] initWithRequest:[[self class] canonicalRequestForRequest:self.request] delegate:self startImmediately:YES];
#pragma clang diagnostic pop
    self.startTime = [[NSDate date] timeIntervalSince1970];
}

- (void)stopLoading
{
    [self.connection cancel];
    
    CCDebugHttpModel *model = [[CCDebugHttpModel alloc] init];
    model.url = self.request.URL;
    model.method = self.request.HTTPMethod;
    model.requestAllHeaderFields = self.request.allHTTPHeaderFields;
    [model cpmversopmCachePolicy:self.request.cachePolicy];
    @try {
        if (self.request.HTTPBody) {
            model.requestBody = [CCDebugHttpDataSource prettyJSONStringFromData:self.request.HTTPBody];
            model.requestDataSize = self.request.HTTPBody.length;
        }
    } @catch (NSException *exception) {
    } @finally {
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)self.response;
    model.statusCode = [NSString stringWithFormat:@"%d", (int)httpResponse.statusCode];
    
    NSString *mineType = self.response.MIMEType;
    if ([self.response textEncodingName])
        mineType = [NSString stringWithFormat:@"%@; charset=%@", self.response.MIMEType, [self.response textEncodingName]];
    
    model.mineType = mineType;
    model.responseAllHeaderFields = httpResponse.allHeaderFields;
    if (self.data) {
        model.responseBody = [CCDebugHttpDataSource prettyJSONStringFromData:self.data];
        model.responseData = self.data;
    }
    model.isImage = [self.response.MIMEType rangeOfString:@"image"].location != NSNotFound;
    model.totalDuration = [NSString stringWithFormat:@"%fs", [[NSDate date] timeIntervalSince1970] - self.startTime];
    model.startTime = [NSString stringWithFormat:@"%fs", self.startTime];
    model.expectedContentLength += self.response.expectedContentLength;
    
    [[CCDebugHttpDataSource manager] addHttpRequset:model];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCCNotifyKeyReloadHttp object:nil];
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[self client] URLProtocol:self didFailWithError:error];
    self.error = error;
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [[self client] URLProtocol:self didReceiveAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [[self client] URLProtocol:self didCancelAuthenticationChallenge:challenge];
}

#pragma mark - NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    self.response = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self client] URLProtocol:self didLoadData:data];
    [self.data appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[self client] URLProtocolDidFinishLoading:self];
}

@end
