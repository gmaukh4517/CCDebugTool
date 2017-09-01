//
//  CCDebugHttpDataSource.h
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

#import <Foundation/Foundation.h>

@interface CCDebugHttpModel : NSObject

@property (nonatomic, copy) NSString *requestId;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *method;
@property (nonatomic, copy) NSString *statusCode;
@property (nonatomic, copy) NSString *mineType;
@property (nonatomic, copy) NSString *startTime;
@property (nonatomic, copy) NSString *totalDuration;

@property (nonatomic, strong) NSString *requestCachePolicy;
@property (nonatomic, copy) NSDictionary *requestAllHeaderFields;
@property (nonatomic, copy) NSString *requestBody;
@property (nonatomic, assign) NSInteger requestDataSize;

@property (nonatomic, copy) NSDictionary *responseAllHeaderFields;
@property (nonatomic, copy) NSString *responseBody;
@property (nonatomic, copy) NSData *responseData;

@property (nonatomic, assign) long long expectedContentLength;

@property (nonatomic, assign) BOOL isImage;

- (void)cpmversopmCachePolicy:(NSInteger)cachePolicy;

@end

@interface CCDebugHttpDataSource : NSObject

@property (nonatomic, strong, readonly) NSMutableArray *httpArray;
@property (nonatomic, strong, readonly) NSMutableArray *arrRequest;


+ (instancetype)manager;

/**
 *  记录http请求
 *
 *  @param model http
 */
- (void)addHttpRequset:(CCDebugHttpModel *)model;

/**
 *  清空
 */
- (void)clear;

/** 解析 **/
+ (NSString *)prettyJSONStringFromData:(id)data;

@end
