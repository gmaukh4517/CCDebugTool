//
//  CCMonitorHelper.m
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

#import "CCMonitorHelper.h"
#include <ifaddrs.h>
#import <mach/mach.h>
#include <malloc/malloc.h>
#include <net/if.h>
#include <sys/mount.h>
#include <sys/param.h>
#include <sys/socket.h>
#import <sys/sysctl.h>

#define KB (1024)
#define MB (KB * 1024)
#define GB (MB * 1024)

static vm_size_t ccPageSize = 0;
static vm_statistics_data_t ccStats;

@interface CCMonitorHelper ()

@property (assign, nonatomic) float preWWAN_R;

@property (assign, nonatomic) float preWWAN_S;

@property (assign, nonatomic) float preWifi_R;

@property (assign, nonatomic) float preWifi_S;

@end

@implementation CCMonitorHelper

+ (NSString *)bytesOfTotalMemory
{
    [self updateHostStatistics];
    
    unsigned long long free_count = (unsigned long long)ccStats.free_count;
    unsigned long long active_count = (unsigned long long)ccStats.active_count;
    unsigned long long inactive_count = (unsigned long long)ccStats.inactive_count;
    unsigned long long wire_count = (unsigned long long)ccStats.wire_count;
    unsigned long long pageSize = (unsigned long long)ccPageSize;
    
    unsigned long long mem_free = (free_count + active_count + inactive_count + wire_count) * pageSize;
    return [self number2String:mem_free];
}

//for internal use
+ (BOOL)updateHostStatistics
{
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &ccPageSize);
    return (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&ccStats, &host_size) == KERN_SUCCESS);
}

/**
 使用内存
 */
+ (NSString *)bytesOfUsedMemory
{
    struct mstats stat = mstats();
    return [self number2String:stat.bytes_used];
}

// 获取总内存大小
+ (NSString *)getTotalMemory
{
    return [self number2String:[CCMonitorHelper getTotalMemorySize]];
}

+ (float)getTotalMemorySize
{
    return [NSProcessInfo processInfo].physicalMemory;
}

// 获取当前设备的 Memory 使用情况
+ (NSString *)getUsedMemory
{
    return [self number2String:[self getUsedMemorySize]];
}

// 获取当前设备的 Memory 使用情况
+ (int64_t)getUsedMemorySize
{
    size_t length = 0;
    int mib[6] = {0};
    
    int pagesize = 0;
    mib[0] = CTL_HW;
    mib[1] = HW_PAGESIZE;
    length = sizeof(pagesize);
    if (sysctl(mib, 2, &pagesize, &length, NULL, 0) < 0)
        return 0;
    
    mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
    vm_statistics_data_t vmstat;
    if (host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmstat, &count) != KERN_SUCCESS)
        return 0;
    
    int wireMem = vmstat.wire_count * pagesize;
    int activeMem = vmstat.active_count * pagesize;
    return wireMem + activeMem;
}

//获取当前 App Memory 的使用情况
+ (NSString *)getResidentMemory
{
    return [self number2String:[self getResidentMemorySize]];
}

//获取当前 App Memory 的使用情况
+ (NSUInteger)getResidentMemorySize
{
    struct mach_task_basic_info taskInfo;
    mach_msg_type_number_t infoCount = MACH_TASK_BASIC_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&taskInfo, &infoCount);
    
    if (kernReturn != KERN_SUCCESS)
        return NSNotFound;
    
    return (NSUInteger)taskInfo.resident_size;
}

// 获取当前设备可用内存
+ (NSString *)availableMemory
{
    return [self number2String:[CCMonitorHelper availableMemorySize]];
}

+ (float)availableMemorySize
{
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(),
                                               HOST_VM_INFO,
                                               (host_info_t)&vmStats,
                                               &infoCount);
    
    if (kernReturn != KERN_SUCCESS)
        return NSNotFound;
    
    return vm_page_size * vmStats.free_count;
}

//获取总磁盘容量
+ (NSString *)getTotalDiskSize
{
    struct statfs buf;
    unsigned long long freeSpace = -1;
    if (statfs("/var", &buf) >= 0) {
        freeSpace = (unsigned long long)(buf.f_bsize * buf.f_blocks);
    }
    return [self number2String:freeSpace];
}

// 获取当前设备可用存储
+ (NSString *)getAvailableDiskSize
{
    struct statfs buf;
    unsigned long long freeSpace = -1;
    if (statfs("/var", &buf) >= 0) {
        freeSpace = (unsigned long long)(buf.f_bsize * buf.f_bavail);
    }
    return [self number2String:freeSpace];
}

// 赋值当前流量
+ (NSArray *)currentLiuLiang
{
    return [NSArray arrayWithObjects:[self getDataCounters][0],
            [self getDataCounters][1],
            [self getDataCounters][2],
            [self getDataCounters][3], nil];
}

// 上行、下行流量
+ (NSArray *)getDataCounters
{
    BOOL success;
    struct ifaddrs *addrs;
    struct ifaddrs *cursor;
    struct if_data *networkStatisc;
    int WiFiSent = 0;
    int WiFiReceived = 0;
    int WWANSent = 0;
    int WWANReceived = 0;
    NSString *name = [[NSString alloc] init];
    success = getifaddrs(&addrs) == 0;
    if (success) {
        cursor = addrs;
        while (cursor != NULL) {
            name = [NSString stringWithFormat:@"%s", cursor->ifa_name];
            if (cursor->ifa_addr->sa_family == AF_LINK) {
                if ([name hasPrefix:@"en"]) {
                    networkStatisc = (struct if_data *)cursor->ifa_data;
                    WiFiSent += networkStatisc->ifi_obytes;
                    WiFiReceived += networkStatisc->ifi_ibytes;
                }
                
                if ([name hasPrefix:@"pdp_ip"]) {
                    networkStatisc = (struct if_data *)cursor->ifa_data;
                    WWANSent += networkStatisc->ifi_obytes;
                    WWANReceived += networkStatisc->ifi_ibytes;
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    return [NSArray arrayWithObjects:[NSNumber numberWithInt:WiFiSent],
            [NSNumber numberWithInt:WiFiReceived],
            [NSNumber numberWithInt:WWANSent],
            [NSNumber numberWithInt:WWANReceived], nil];
}

// cpu
+ (float)cpu_usage
{
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t basic_info;
    thread_array_t thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++) {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
    return tot_cpu;
}

+ (NSString *)number2String:(int64_t)n
{
    if (n < KB) {
        return [NSString stringWithFormat:@"%lldB", n];
    } else if (n < MB) {
        return [NSString stringWithFormat:@"%.1fKB", (float)n / (float)KB];
    } else if (n < GB) {
        return [NSString stringWithFormat:@"%.1fMB", (float)n / (float)MB];
    } else {
        return [NSString stringWithFormat:@"%.1fG", (float)n / (float)GB];
    }
}

@end
