//
//  CCDebugEnterLOGHelper.m
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

#import "CCDebugEnterLOGHelper.h"
#import <asl.h>
#include <stdio.h>

@implementation CCDebugLogModel

+ (instancetype)messageFromASLMessage:(aslmsg)aslMessage
{
    CCDebugLogModel *logMessage = [[CCDebugLogModel alloc] init];
    
    const char *timestamp = asl_get(aslMessage, ASL_KEY_TIME);
    if (timestamp) {
        NSTimeInterval timeInterval = [@(timestamp) integerValue];
        const char *nanoseconds = asl_get(aslMessage, ASL_KEY_TIME_NSEC);
        if (nanoseconds) {
            timeInterval += [@(nanoseconds) doubleValue] / NSEC_PER_SEC;
        }
        logMessage.date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    }
    
    const char *sender = asl_get(aslMessage, ASL_KEY_SENDER);
    if (sender) {
        logMessage.sender = @(sender);
    }
    
    const char *messageText = asl_get(aslMessage, ASL_KEY_MSG);
    if (messageText) {
        NSString *format = @(messageText);
        format = ({
            format = [format stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
            format = [format stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            format = [format stringByReplacingOccurrencesOfString:@"\\\\U" withString:@"\\U"];
            format = [[@"\"" stringByAppendingString:format] stringByAppendingString:@"\""];
            format = [NSPropertyListSerialization propertyListWithData:[format dataUsingEncoding:NSUTF8StringEncoding] options:NSPropertyListImmutable format:nil error:nil];
            format = [format stringByReplacingOccurrencesOfString:@"\0" withString:@""];
            [format stringByReplacingOccurrencesOfString:@"\\r\\n" withString:@"\n"];
        });
        logMessage.messageText = format;
    }
    
    const char *messageID = asl_get(aslMessage, ASL_KEY_MSG_ID);
    if (messageID) {
        logMessage.messageID = [@(messageID) longLongValue];
    }
    
    return logMessage;
}

+ (NSString *)stringFormatFromDate:(NSDate *)date
{
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    });
    
    return [formatter stringFromDate:date];
}

@end

@implementation CCDebugEnterLOGHelper

+ (NSArray *)logs:(int)maxLogsCount
{
    asl_object_t query = asl_new(ASL_TYPE_QUERY);
    char pidStr[100];
    sprintf(pidStr, "%d", [[NSProcessInfo processInfo] processIdentifier]);
    asl_set_query(query, ASL_KEY_PID, pidStr, ASL_QUERY_OP_EQUAL);
    
    //this is too slow!
    aslresponse response = asl_search(NULL, query);
    NSUInteger numberOfLogs = maxLogsCount;
    NSMutableArray *logMessages = [NSMutableArray arrayWithCapacity:numberOfLogs];
    size_t count = asl_count(response);
    for (int i = 0; i < numberOfLogs; i++) {
        aslmsg msg = asl_get_index(response, count - i - 1);
        if (msg != NULL) {
            CCDebugLogModel *model = [CCDebugLogModel messageFromASLMessage:msg];
            [logMessages addObject:model];
        } else
            break;
    }
    asl_release(response);
    return logMessages;
}

@end
