//
//  CCCookieManager.m
//  CCDebugTool
//
//  Created by CC on 2017/11/22.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCCookieManager.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

NSString *const kCCUtilityAttributeTypeEncoding = @"T";

@implementation CCCookieManager


+ (NSArray *)cookiesProperties:(id)object
{
    NSMutableArray *cookies = [NSMutableArray array];
    unsigned int outCount = 0;
    objc_property_t *properties = class_copyPropertyList([object class], &outCount);
    for (unsigned int i = 0; i < outCount; i++) {
        objc_property_t property = properties[ i ];
        NSMutableDictionary *item = [NSMutableDictionary dictionary];
        //获取成员变量的名
        NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
        if ([propertyName containsString:@"_"])
            propertyName = [propertyName substringFromIndex:1];
        [item setObject:propertyName forKey:@"propertyName"];
        //属性描述
        NSString *propertyType = [CCCookieManager typeEncodingForProperty:property];
        [item setObject:propertyType forKey:@"propertyType"];
        
        NSString *title = [CCCookieManager appendName:propertyName toType:propertyType];
        [item setObject:title forKey:@"title"];

        NSDictionary *valueDic = [CCCookieManager descriptionForIvarOrPropertyValue:[object valueForKey:propertyName]];
        [item setObject:[valueDic objectForKey:@"description"] forKey:@"propertyValue"];
        [item setObject:[valueDic objectForKey:@"valeStr"] forKey:@"value"];

        [cookies addObject:item];
    }
    free(properties);


    return cookies;
}

+ (NSString *)appendName:(NSString *)name toType:(NSString *)type
{
    NSString *combined = nil;
    if ([type characterAtIndex:[type length] - 1] == '*') {
        combined = [type stringByAppendingString:name];
    } else {
        combined = [type stringByAppendingFormat:@" %@", name];
    }
    return combined;
}

+ (NSString *)typeEncodingForProperty:(objc_property_t)property
{
    NSString *attributes = @(property_getAttributes(property));
    // Thanks to MAObjcRuntime for inspiration here.
    NSArray *attributePairs = [attributes componentsSeparatedByString:@","];
    NSMutableDictionary *attributesDictionary = [NSMutableDictionary dictionaryWithCapacity:[attributePairs count]];
    for (NSString *attributePair in attributePairs) {
        [attributesDictionary setObject:[attributePair substringFromIndex:1] forKey:[attributePair substringToIndex:1]];
    }
    return [CCCookieManager readableTypeForEncoding:attributesDictionary[@"T"]];
}

+ (NSString *)readableTypeForEncoding:(NSString *)encodingString
{
    if (!encodingString)
        return nil;
        
    const char *encodingCString = [encodingString UTF8String];
    
    // Objects
    if (encodingCString[0] == '@') {
        NSString *class = [encodingString substringFromIndex:1];
        class = [class stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        if ([class length] == 0 || [class isEqual:@"?"]) {
            class = @"id";
        } else {
            class = [class stringByAppendingString:@" *"];
        }
        return class;
    }
    
    // C Types
#define TRANSLATE(ctype) \
if (strcmp(encodingCString, @encode(ctype)) == 0) { \
return (NSString *)CFSTR(#ctype); \
}
    
    // Order matters here since some of the cocoa types are typedefed to c types.
    // We can't recover the exact mapping, but we choose to prefer the cocoa types.
    // This is not an exhaustive list, but it covers the most common types
    TRANSLATE(CGRect);
    TRANSLATE(CGPoint);
    TRANSLATE(CGSize);
    TRANSLATE(UIEdgeInsets);
    TRANSLATE(UIOffset);
    TRANSLATE(NSRange);
    TRANSLATE(CGAffineTransform);
    TRANSLATE(CATransform3D);
    TRANSLATE(CGColorRef);
    TRANSLATE(CGPathRef);
    TRANSLATE(CGContextRef);
    TRANSLATE(NSInteger);
    TRANSLATE(NSUInteger);
    TRANSLATE(CGFloat);
    TRANSLATE(BOOL);
    TRANSLATE(int);
    TRANSLATE(short);
    TRANSLATE(long);
    TRANSLATE(long long);
    TRANSLATE(unsigned char);
    TRANSLATE(unsigned int);
    TRANSLATE(unsigned short);
    TRANSLATE(unsigned long);
    TRANSLATE(unsigned long long);
    TRANSLATE(float);
    TRANSLATE(double);
    TRANSLATE(long double);
    TRANSLATE(char *);
    TRANSLATE(Class);
    TRANSLATE(objc_property_t);
    TRANSLATE(Ivar);
    TRANSLATE(Method);
    TRANSLATE(Category);
    TRANSLATE(NSZone *);
    TRANSLATE(SEL);
    TRANSLATE(void);
    
#undef TRANSLATE
    
    // Qualifier Prefixes
    // Do this after the checks above since some of the direct translations (i.e. Method) contain a prefix.
#define RECURSIVE_TRANSLATE(prefix, formatString) \
if (encodingCString[0] == prefix) { \
NSString *recursiveType = [self readableTypeForEncoding:[encodingString substringFromIndex:1]]; \
return [NSString stringWithFormat:formatString, recursiveType]; \
}
    
    // If there's a qualifier prefix on the encoding, translate it and then
    // recursively call this method with the rest of the encoding string.
    RECURSIVE_TRANSLATE('^', @"%@ *");
    RECURSIVE_TRANSLATE('r', @"const %@");
    RECURSIVE_TRANSLATE('n', @"in %@");
    RECURSIVE_TRANSLATE('N', @"inout %@");
    RECURSIVE_TRANSLATE('o', @"out %@");
    RECURSIVE_TRANSLATE('O', @"bycopy %@");
    RECURSIVE_TRANSLATE('R', @"byref %@");
    RECURSIVE_TRANSLATE('V', @"oneway %@");
    RECURSIVE_TRANSLATE('b', @"bitfield(%@)");
    
#undef RECURSIVE_TRANSLATE
    
    // If we couldn't translate, just return the original encoding string
    return encodingString;
}

/** 获取值 **/
+ (NSDictionary *)descriptionForIvarOrPropertyValue:(id)value
{
    NSString *description = nil;
    NSString *valeStr = nil;
    // Special case BOOL for better readability.
    if ([value isKindOfClass:[NSValue class]]) {
        const char *type = [value objCType];
        if (strcmp(type, @encode(BOOL)) == 0) {
            BOOL boolValue = NO;
            [value getValue:&boolValue];
            description = boolValue ? @"YES" : @"NO";
        } else if (strcmp(type, @encode(SEL)) == 0) {
            SEL selector = NULL;
            [value getValue:&selector];
            description = NSStringFromSelector(selector);
        }
    }

    if (!description) {
        // Single line display - replace newlines and tabs with spaces.
        description = [value description];
        valeStr = [[value description] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        valeStr = [valeStr stringByReplacingOccurrencesOfString:@"\t" withString:@" "];
    }

    if (!valeStr) {
        valeStr = @"nil";
        description = @"nil";
    }

    return @{@"valeStr":valeStr,@"description":description};
}

@end
