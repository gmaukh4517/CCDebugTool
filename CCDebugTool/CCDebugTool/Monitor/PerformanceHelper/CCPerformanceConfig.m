//
//  CCPerformanceConfig.m
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

#import "CCPerformanceConfig.h"

@implementation CCPerformanceConfig

+ (instancetype)defaultConfigForAttribtue:(CCPerformanceMonitorAttributes)attribute
{
    if (attribute == CCPerformanceMonitorMemory) {
        return [self configWithGood:150.0 warning:200.0 lessIsBetter:YES];
    }
    if (attribute == CCPerformanceMonitorFPS) {
        return [self configWithGood:55.0 warning:40.0 lessIsBetter:NO];
    }
    if (attribute == CCPerformanceMonitorCPU) {
        return [self configWithGood:70.0 warning:90.0 lessIsBetter:YES];
        ;
    }
    return nil;
}
+ (instancetype)configWithGood:(CGFloat)good warning:(CGFloat)warning lessIsBetter:(BOOL)lessIsBetter
{
    CCPerformanceConfig *config = [[CCPerformanceConfig alloc] init];
    config.lessIsBetter = lessIsBetter;
    config.goodThreshold = good;
    config.warningThreadhold = warning;
    return config;
}

@end
