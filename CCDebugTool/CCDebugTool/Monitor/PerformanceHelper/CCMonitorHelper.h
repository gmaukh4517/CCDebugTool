//
//  CCMonitorHelper.h
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

@interface CCMonitorHelper : NSObject

+ (NSString *)bytesOfTotalMemory;

//for internal use
+ (BOOL)updateHostStatistics;

// 使用内存
+ (NSString *)bytesOfUsedMemory;

// 获取总内存大小
+ (NSString *)getTotalMemory;
+ (float)getTotalMemorySize;

// 获取当前设备的 Memory 使用情况
+ (NSString *)getUsedMemory;
+ (int64_t)getUsedMemorySize;
//获取当前 App Memory 的使用情况
+ (NSString *)getResidentMemory;
+ (NSUInteger)getResidentMemorySize;

// 获取当前设备可用内存
+ (NSString *)availableMemory;
+ (float)availableMemorySize;

//获取总磁盘容量
+ (NSString *)getTotalDiskSize;

// 获取当前设备可用存储
+ (NSString *)getAvailableDiskSize;

// 赋值当前流量
+ (NSArray *)currentLiuLiang;

// 上行、下行流量
+ (NSArray *)getDataCounters;

// cpu
+ (float)cpu_usage;

@end
