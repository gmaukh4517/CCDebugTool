//
//  CCDebugHttpDataSource.m
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

#import "CCDebugHttpDataSource.h"

@implementation CCDebugHttpModel

- (NSString *)startTime
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:_startTime.doubleValue]];
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

@implementation CCDebugHttpDataSource


+ (instancetype)manager
{
    static CCDebugHttpDataSource *tool;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        tool = [[CCDebugHttpDataSource alloc] init];
    });
    return tool;
}

- (id)init
{
    self = [super init];
    if (self) {
        _httpArray = [NSMutableArray array];
        _arrRequest = [NSMutableArray array];
    }
    return self;
}

- (void)addHttpRequset:(CCDebugHttpModel *)model
{
    @synchronized(self.httpArray)
    {
        [self.httpArray insertObject:model atIndex:0];
    }
    @synchronized(self.arrRequest)
    {
        if (model.requestId && model.requestId.length > 0) {
            [self.arrRequest addObject:model.requestId];
        }
    }
}

- (void)clear
{
    @synchronized(self.httpArray)
    {
        [self.httpArray removeAllObjects];
    }
    @synchronized(self.arrRequest)
    {
        [self.arrRequest removeAllObjects];
    }
}


#pragma mark - parse
+ (NSString *)prettyJSONStringFromData:(id)data
{
    NSString *prettyString = nil;
    if ([data isKindOfClass:[NSDictionary class]]) {
        prettyString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:NULL] encoding:NSUTF8StringEncoding];
    } else if ([data isKindOfClass:[NSData class]]) {
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        if ([NSJSONSerialization isValidJSONObject:jsonObject]) {
            prettyString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:NULL] encoding:NSUTF8StringEncoding];
        } else {
            prettyString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    
    if (prettyString)
        prettyString = [prettyString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    
    return prettyString;
}


@end
