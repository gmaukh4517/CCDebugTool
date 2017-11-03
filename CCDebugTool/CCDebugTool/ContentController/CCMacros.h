//
//  CCMacros.h
//  CCDebugTool
//
//  Created by CC on 2017/9/1.
//  Copyright © 2017年 CC. All rights reserved.
//

#ifndef CCMacros_h
#define CCMacros_h

#import <pthread.h>
#include <sys/sysctl.h>


static inline NSString *hardwareString()
{
    int name[] = {CTL_HW, HW_MACHINE};
    size_t size = 100;
    sysctl(name, 2, NULL, &size, NULL, 0); // getting size of answer
    char *hw_machine = malloc(size);
    
    sysctl(name, 2, hw_machine, &size, NULL, 0);
    NSString *hardware = [NSString stringWithUTF8String:hw_machine];
    free(hw_machine);
    return hardware;
}

static inline NSString *hardwareDescription()
{
    NSString *hardware = hardwareString();
    if ([hardware isEqualToString:@"iPhone1,1"]) return @"iPhone 2G";		  // (A1203)
    if ([hardware isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";		  // (A1241/A1324)
    if ([hardware isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";		  // (A1303/A1325)
    if ([hardware isEqualToString:@"iPhone3,1"]) return @"iPhone 4 (GSM)";	// (A1332)
    if ([hardware isEqualToString:@"iPhone3,2"]) return @"iPhone 4 (GSM Rev. A)"; // (A1332)
    if ([hardware isEqualToString:@"iPhone3,3"]) return @"iPhone 4 (CDMA)";       // (A1349)
    if ([hardware isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";		  // (A1387/A1431)
    if ([hardware isEqualToString:@"iPhone5,1"]) return @"iPhone 5 (GSM)";	// (A1428)
    if ([hardware isEqualToString:@"iPhone5,2"]) return @"iPhone 5 (Global)";     // (A1429/A1442)
    if ([hardware isEqualToString:@"iPhone5,3"]) return @"iPhone 5C (GSM)";       // (A1456/A1532)
    if ([hardware isEqualToString:@"iPhone5,4"]) return @"iPhone 5C (Global)";    // (A1507/A1516/A1526/A1529)
    if ([hardware isEqualToString:@"iPhone6,1"]) return @"iPhone 5S (GSM)";       // (A1453/A1533)
    if ([hardware isEqualToString:@"iPhone6,2"]) return @"iPhone 5S (Global)";    // (A1457/A1518/A1528/A1530)
    
    if ([hardware isEqualToString:@"iPhone7,1"]) return @"iPhone 6 Plus"; // (A1522/A1524)
    if ([hardware isEqualToString:@"iPhone7,2"]) return @"iPhone 6";      // (A1549/A1586)
    
    if ([hardware isEqualToString:@"iPod1,1"]) return @"iPod Touch (1 Gen)"; // (A1213)
    if ([hardware isEqualToString:@"iPod2,1"]) return @"iPod Touch (2 Gen)"; // (A1288)
    if ([hardware isEqualToString:@"iPod3,1"]) return @"iPod Touch (3 Gen)"; // (A1318)
    if ([hardware isEqualToString:@"iPod4,1"]) return @"iPod Touch (4 Gen)"; // (A1367)
    if ([hardware isEqualToString:@"iPod5,1"]) return @"iPod Touch (5 Gen)"; // (A1421/A1509)
    
    if ([hardware isEqualToString:@"iPad1,1"]) return @"iPad (WiFi)"; // (A1219/A1337)
    if ([hardware isEqualToString:@"iPad1,2"]) return @"iPad 3G";
    
    if ([hardware isEqualToString:@"iPad2,1"]) return @"iPad 2 (WiFi)";	// (A1395)
    if ([hardware isEqualToString:@"iPad2,2"]) return @"iPad 2 (GSM)";	 // (A1396)
    if ([hardware isEqualToString:@"iPad2,3"]) return @"iPad 2 (CDMA)";	// (A1397)
    if ([hardware isEqualToString:@"iPad2,4"]) return @"iPad 2 (WiFi Rev. A)"; // (A1395+New Chip)
    if ([hardware isEqualToString:@"iPad2,5"]) return @"iPad Mini (WiFi)";     // (A1432)
    if ([hardware isEqualToString:@"iPad2,6"]) return @"iPad Mini (GSM)";      // (A1454)
    if ([hardware isEqualToString:@"iPad2,7"]) return @"iPad Mini (CDMA)";     // (A1455)
    
    if ([hardware isEqualToString:@"iPad3,1"]) return @"iPad 3 (WiFi)";   // (A1416)
    if ([hardware isEqualToString:@"iPad3,2"]) return @"iPad 3 (CDMA)";   // (A1403)
    if ([hardware isEqualToString:@"iPad3,3"]) return @"iPad 3 (Global)"; // (A1430)
    if ([hardware isEqualToString:@"iPad3,4"]) return @"iPad 4 (WiFi)";   // (A1458)
    if ([hardware isEqualToString:@"iPad3,5"]) return @"iPad 4 (CDMA)";   // (A1459)
    if ([hardware isEqualToString:@"iPad3,6"]) return @"iPad 4 (Global)"; // (A1460)
    
    if ([hardware isEqualToString:@"iPad4,1"]) return @"iPad Air (WiFi)";	      // (A1474)
    if ([hardware isEqualToString:@"iPad4,2"]) return @"iPad Air (WiFi+GSM)";	  // (A1475)
    if ([hardware isEqualToString:@"iPad4,3"]) return @"iPad Air (WiFi+CDMA)";	 // (A1476)
    if ([hardware isEqualToString:@"iPad4,4"]) return @"iPad Mini Retina (WiFi)";      // (A1489)
    if ([hardware isEqualToString:@"iPad4,5"]) return @"iPad Mini Retina (WiFi+CDMA)"; // (A1490)
    if ([hardware isEqualToString:@"iPad4,6"]) return @"iPad Mini 2G";		       // (A1491)
    
    if ([hardware isEqualToString:@"i386"]) return @"Simulator";
    if ([hardware isEqualToString:@"x86_64"]) return @"Simulator";
    
    NSLog(@"This is a device which is not listed in this category. Please visit https://github.com/inderkumarrathore/UIDevice-Hardware and add a comment there.");
    NSLog(@"Your device hardware string is: %@", hardware);
    if ([hardware hasPrefix:@"iPhone"]) return @"iPhone";
    if ([hardware hasPrefix:@"iPod"]) return @"iPod";
    if ([hardware hasPrefix:@"iPad"]) return @"iPad";
    return nil;
}

/** 判断设备是否越狱 **/
static inline int cc_isJailbreak()
{
    /** 越狱工具路径 **/
    const char *jailbreak_tool_pathes[] = {
        "/Applications/Cydia.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/etc/apt",
    };
    
    int appay_size = sizeof(jailbreak_tool_pathes) / sizeof(jailbreak_tool_pathes[0]);
    for (int i = 0; i < appay_size; i++) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:jailbreak_tool_pathes[i]]]) {
            return YES;
        }
    }
    return NO;
}


#endif /* CCMacros_h */
