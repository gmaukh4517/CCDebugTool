//
//  CCCookieManager.m
//  CCDebugTool
//
//  Created by CC on 2017/11/22.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCCookieManager.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

typedef NS_ENUM(char, CCTypeEncoding) {
    CCTypeEncodingUnknown = '?',
    CCTypeEncodingChar = 'c',
    CCTypeEncodingInt = 'i',
    CCTypeEncodingShort = 's',
    CCTypeEncodingLong = 'l',
    CCTypeEncodingLongLong = 'q',
    CCTypeEncodingUnsignedChar = 'C',
    CCTypeEncodingUnsignedInt = 'I',
    CCTypeEncodingUnsignedShort = 'S',
    CCTypeEncodingUnsignedLong = 'L',
    CCTypeEncodingUnsignedLongLong = 'Q',
    CCTypeEncodingFloat = 'f',
    CCTypeEncodingDouble = 'd',
    CCTypeEncodingLongDouble = 'D',
    CCTypeEncodingCBool = 'B',
    CCTypeEncodingVoid = 'v',
    CCTypeEncodingCString = '*',
    CCTypeEncodingObjcObject = '@',
    CCTypeEncodingObjcClass = '#',
    CCTypeEncodingSelector = ':',
    CCTypeEncodingArrayBegin = '[',
    CCTypeEncodingArrayEnd = ']',
    CCTypeEncodingStructBegin = '{',
    CCTypeEncodingStructEnd = '}',
    CCTypeEncodingUnionBegin = '(',
    CCTypeEncodingUnionEnd = ')',
    CCTypeEncodingQuote = '\"',
    CCTypeEncodingBitField = 'b',
    CCTypeEncodingPointer = '^',
    CCTypeEncodingConst = 'r'
};

NSString *const kCCUtilityAttributeTypeEncoding = @"T";
NSString *const kCCUtilityAttributeBackingIvar = @"V";
NSString *const kCCUtilityAttributeReadOnly = @"R";
NSString *const kCCUtilityAttributeCopy = @"C";
NSString *const kCCUtilityAttributeRetain = @"&";
NSString *const kCCUtilityAttributeNonAtomic = @"N";
NSString *const kCCUtilityAttributeCustomGetter = @"G";
NSString *const kCCUtilityAttributeCustomSetter = @"S";
NSString *const kCCUtilityAttributeDynamic = @"D";
NSString *const kCCUtilityAttributeWeak = @"W";
NSString *const kCCUtilityAttributeGarbageCollectable = @"P";
NSString *const kCCUtilityAttributeOldStyleTypeEncoding = @"t";

static NSString *const CCRuntimeUtilityErrorDomain = @"CCRuntimeUtilityErrorDomain";
typedef NS_ENUM(NSInteger, CCRuntimeUtilityErrorCode) {
    CCRuntimeUtilityErrorCodeDoesNotRecognizeSelector = 0,
    CCRuntimeUtilityErrorCodeInvocationFailed = 1,
    CCRuntimeUtilityErrorCodeArgumentTypeMismatch = 2
};

// Arguments 0 and 1 are self and _cmd always
const unsigned int kCCNumberOfImplicitArgs = 2;

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
        NSString *propertyName = @(property_getName(property));
        if ([propertyName hasPrefix:@"_"])
            propertyName = [propertyName substringFromIndex:1];
        [item setObject:propertyName forKey:@"propertyName"];
        //属性描述
        NSString *propertyType = [CCCookieManager typeEncodingForProperty:property];
        [item setObject:propertyType forKey:@"propertyType"];

        [item setObject:[CCCookieManager prettyNameForProperty:property] forKey:@"title"];
        NSDictionary *valueDic = [CCCookieManager descriptionForIvarOrPropertyValue:[CCCookieManager valueForProperty:property onObject:object]];
        [item setObject:[valueDic objectForKey:@"description"] forKey:@"propertyValue"];
        [item setObject:[valueDic objectForKey:@"valeStr"] forKey:@"value"];

        [cookies addObject:item];
    }
    free(properties);


    return cookies;
}

+ (NSString *)prettyNameForProperty:(objc_property_t)property
{
    NSString *name = @(property_getName(property));
    NSString *encoding = [self typeEncodingForProperty:property];
    NSString *readableType = [self readableTypeForEncoding:encoding];
    return [self appendName:name toType:readableType];
}

+ (NSString *)typeEncodingForProperty:(objc_property_t)property
{
    NSDictionary<NSString *, NSString *> *attributesDictionary = [self attributesDictionaryForProperty:property];
    return attributesDictionary[ kCCUtilityAttributeTypeEncoding ];
}

+ (NSDictionary<NSString *, NSString *> *)attributesDictionaryForProperty:(objc_property_t)property
{
    NSString *attributes = @(property_getAttributes(property));
    // Thanks to MAObjcRuntime for inspiration here.
    NSArray<NSString *> *attributePairs = [attributes componentsSeparatedByString:@","];
    NSMutableDictionary<NSString *, NSString *> *attributesDictionary = [NSMutableDictionary dictionaryWithCapacity:attributePairs.count];
    for (NSString *attributePair in attributePairs) {
        [attributesDictionary setObject:[attributePair substringFromIndex:1] forKey:[attributePair substringToIndex:1]];
    }
    return attributesDictionary;
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

+ (NSString *)readableTypeForEncoding:(NSString *)encodingString
{
    if (!encodingString) {
        return nil;
    }

    // See https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
    // class-dump has a much nicer and much more complete implementation for this task, but it is distributed under GPLv2 :/
    // See https://github.com/nygard/class-dump/blob/master/Source/CDType.m
    // Warning: this method uses multiple middle returns and macros to cut down on boilerplate.
    // The use of macros here was inspired by https://www.mikeash.com/pyblog/friday-qa-2013-02-08-lets-build-key-value-coding.html
    const char *encodingCString = encodingString.UTF8String;

    // Some fields have a name, such as {Size=\"width\"d\"height\"d}, we need to extract the name out and recursive
    const NSUInteger fieldNameOffset = [CCCookieManager fieldNameOffsetForTypeEncoding:encodingCString];
    if (fieldNameOffset > 0) {
        // According to https://github.com/nygard/class-dump/commit/33fb5ed221810685f57c192e1ce8ab6054949a7c,
        // there are some consecutive quoted strings, so use `_` to concatenate the names.
        NSString *const fieldNamesString = [encodingString substringWithRange:NSMakeRange(0, fieldNameOffset)];
        NSArray<NSString *> *const fieldNames = [fieldNamesString componentsSeparatedByString:[NSString stringWithFormat:@"%c", CCTypeEncodingQuote]];
        NSMutableString *finalFieldNamesString = [NSMutableString string];
        for (NSString *const fieldName in fieldNames) {
            if (fieldName.length > 0) {
                if (finalFieldNamesString.length > 0) {
                    [finalFieldNamesString appendString:@"_"];
                }
                [finalFieldNamesString appendString:fieldName];
            }
        }
        NSString *const recursiveType = [self readableTypeForEncoding:[encodingString substringFromIndex:fieldNameOffset]];
        return [NSString stringWithFormat:@"%@ %@", recursiveType, finalFieldNamesString];
    }

    // Objects
    if (encodingCString[ 0 ] == CCTypeEncodingObjcObject) {
        NSString *class = [encodingString substringFromIndex:1];
        class = [class stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%c", CCTypeEncodingQuote] withString:@""];
        if (class.length == 0 || (class.length == 1 && [class characterAtIndex:0] == CCTypeEncodingUnknown)) {
            class = @"id";
        } else {
            class = [class stringByAppendingString:@" *"];
        }
        return class;
    }

    // Qualifier Prefixes
    // Do this first since some of the direct translations (i.e. Method) contain a prefix.
#define RECURSIVE_TRANSLATE(prefix, formatString)                                                       \
if (encodingCString[ 0 ] == prefix) {                                                               \
NSString *recursiveType = [self readableTypeForEncoding:[encodingString substringFromIndex:1]]; \
return [NSString stringWithFormat:formatString, recursiveType];                                 \
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

    // C Types
#define TRANSLATE(ctype)                                \
if (strcmp(encodingCString, @encode(ctype)) == 0) { \
return (NSString *)CFSTR(#ctype);               \
}

    // Order matters here since some of the cocoa types are typedefed to c types.
    // We can't recover the exact mapping, but we choose to prefer the cocoa types.
    // This is not an exhaustive list, but it covers the most common types
    TRANSLATE(CGRect);
    TRANSLATE(CGPoint);
    TRANSLATE(CGSize);
    TRANSLATE(CGVector);
    TRANSLATE(UIEdgeInsets);
    if (@available(iOS 11.0, *)) {
        TRANSLATE(NSDirectionalEdgeInsets);
    }
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

    // For structs, we only use the name of the structs
    if (encodingCString[ 0 ] == CCTypeEncodingStructBegin) {
        const char *equals = strchr(encodingCString, '=');
        if (equals) {
            const char *nameStart = encodingCString + 1;
            // For anonymous structs
            if (nameStart[ 0 ] == CCTypeEncodingUnknown) {
                return @"anonymous struct";
            } else {
                NSString *const structName = [encodingString substringWithRange:NSMakeRange(nameStart - encodingCString, equals - nameStart)];
                return structName;
            }
        }
    }

    // If we couldn't translate, just return the original encoding string
    return encodingString;
}

+ (id)valueForProperty:(objc_property_t)property onObject:(id)object
{
    NSString *customGetterString = nil;
    char *customGetterName = property_copyAttributeValue(property, kCCUtilityAttributeCustomGetter.UTF8String);
    if (customGetterName) {
        customGetterString = @(customGetterName);
        free(customGetterName);
    }

    SEL getterSelector;
    if (customGetterString.length > 0) {
        getterSelector = NSSelectorFromString(customGetterString);
    } else {
        NSString *propertyName = @(property_getName(property));
        getterSelector = NSSelectorFromString(propertyName);
    }

    return [self performSelector:getterSelector onObject:object withArguments:nil error:NULL];
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

    @try {
        if (!description) {
            // Single line display - replace newlines and tabs with spaces.
            description = [value description];
            valeStr = [[value description] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
            valeStr = [description stringByReplacingOccurrencesOfString:@"\t" withString:@" "];
        }
    } @catch (NSException *e) {
        valeStr = [@"Thrown: " stringByAppendingString:e.reason ?: @"(nil exception reason)"];
    }

    if (!description) {
        valeStr = @"nil";
        description = @"nil";
    }

    return @{ @"valeStr" : valeStr,
              @"description" : description };
}

+ (id)performSelector:(SEL)selector onObject:(id)object withArguments:(NSArray *)arguments error:(NSError *__autoreleasing *)error
{
    // Bail if the object won't respond to this selector.
    if (![object respondsToSelector:selector]) {
        if (error) {
            NSDictionary<NSString *, id> *userInfo = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"%@ does not respond to the selector %@", object, NSStringFromSelector(selector)] };
            *error = [NSError errorWithDomain:CCRuntimeUtilityErrorDomain code:CCRuntimeUtilityErrorCodeDoesNotRecognizeSelector userInfo:userInfo];
        }
        return nil;
    }

    // Probably an unsupported type encoding, like bitfields
    // or inline arrays. In the future, we could calculate
    // the return length on our own. For now, we abort.
    //
    // For future reference, the code here will get the true type encoding.
    // NSMethodSignature will convert {?=b8b4b1b1b18[8S]} to {?}
    // A solution might involve hooking NSGetSizeAndAlignment.
    //
    // returnType = method_getTypeEncoding(class_getInstanceMethod([object class], selector));
    NSMethodSignature *methodSignature = [object methodSignatureForSelector:selector];
    if (!methodSignature.methodReturnLength) {
        return nil;
    }

    // Build the invocation
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setSelector:selector];
    [invocation setTarget:object];
    [invocation retainArguments];

    // Always self and _cmd
    NSUInteger numberOfArguments = [methodSignature numberOfArguments];
    for (NSUInteger argumentIndex = kCCNumberOfImplicitArgs; argumentIndex < numberOfArguments; argumentIndex++) {
        NSUInteger argumentsArrayIndex = argumentIndex - kCCNumberOfImplicitArgs;
        id argumentObject = arguments.count > argumentsArrayIndex ? arguments[ argumentsArrayIndex ] : nil;

        // NSNull in the arguments array can be passed as a placeholder to indicate nil. We only need to set the argument if it will be non-nil.
        if (argumentObject && ![argumentObject isKindOfClass:[NSNull class]]) {
            const char *typeEncodingCString = [methodSignature getArgumentTypeAtIndex:argumentIndex];
            if (typeEncodingCString[ 0 ] == CCTypeEncodingObjcObject || typeEncodingCString[ 0 ] == CCTypeEncodingObjcClass || [self isTollFreeBridgedValue:argumentObject forCFType:typeEncodingCString]) {
                // Object
                [invocation setArgument:&argumentObject atIndex:argumentIndex];
            } else if (strcmp(typeEncodingCString, @encode(CGColorRef)) == 0 && [argumentObject isKindOfClass:[UIColor class]]) {
                // Bridging UIColor to CGColorRef
                CGColorRef colorRef = [argumentObject CGColor];
                [invocation setArgument:&colorRef atIndex:argumentIndex];
            } else if ([argumentObject isKindOfClass:[NSValue class]]) {
                // Primitive boxed in NSValue
                NSValue *argumentValue = (NSValue *)argumentObject;

                // Ensure that the type encoding on the NSValue matches the type encoding of the argument in the method signature
                if (strcmp([argumentValue objCType], typeEncodingCString) != 0) {
                    if (error) {
                        NSDictionary<NSString *, id> *userInfo = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Type encoding mismatch for argument at index %lu. Value type: %s; Method argument type: %s.", (unsigned long)argumentsArrayIndex, [argumentValue objCType], typeEncodingCString] };
                        *error = [NSError errorWithDomain:CCRuntimeUtilityErrorDomain code:CCRuntimeUtilityErrorCodeArgumentTypeMismatch userInfo:userInfo];
                    }
                    return nil;
                }

                @try {
                    NSUInteger bufferSize = 0;

                    // NSGetSizeAndAlignment barfs on type encoding for bitfields.
                    NSGetSizeAndAlignment(typeEncodingCString, &bufferSize, NULL);

                    if (bufferSize > 0) {
                        void *buffer = calloc(bufferSize, 1);
                        [argumentValue getValue:buffer];
                        [invocation setArgument:buffer atIndex:argumentIndex];
                        free(buffer);
                    }
                } @catch (NSException *exception) {
                }
            }
        }
    }

    // Try to invoke the invocation but guard against an exception being thrown.
    id returnObject = nil;
    @try {
        // Retrieve the return value and box if necessary.
        const char *returnType = methodSignature.methodReturnType;

        if (returnType[ 0 ] == CCTypeEncodingObjcObject || returnType[ 0 ] == CCTypeEncodingObjcClass) {
            // Return value is an object.
            __unsafe_unretained id objectReturnedFromMethod = nil;
            [invocation getReturnValue:&objectReturnedFromMethod];
            returnObject = objectReturnedFromMethod;
        } else if (returnType[ 0 ] != CCTypeEncodingVoid) {
            NSAssert(methodSignature.methodReturnLength, @"Memory corruption lies ahead");
            // Will use arbitrary buffer for return value and box it.
            void *returnValue = malloc(methodSignature.methodReturnLength);

            if (returnValue) {
                [invocation getReturnValue:returnValue];
                returnObject = [self valueForPrimitivePointer:returnValue objCType:returnType];
                free(returnValue);
            }
        }
    } @catch (NSException *exception) {
        // Bummer...
        if (error) {
            // "… on <class>" / "… on instance of <class>"
            NSString *class = NSStringFromClass([object class]);
            NSString *calledOn = object == [object class] ? class : [@"an instance of " stringByAppendingString:class];

            NSString *message = [NSString stringWithFormat:@"Exception '%@' thrown while performing selector '%@' on %@.\nReason:\n\n%@",
                                 exception.name,
                                 NSStringFromSelector(selector),
                                 calledOn,
                                 exception.reason];

            *error = [NSError errorWithDomain:CCRuntimeUtilityErrorDomain
                                         code:CCRuntimeUtilityErrorCodeInvocationFailed
                                     userInfo:@{NSLocalizedDescriptionKey : message}];
        }
    }

    return returnObject;
}

+ (BOOL)isTollFreeBridgedValue:(id)value forCFType:(const char *)typeEncoding
{
    // See https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/Toll-FreeBridgin/Toll-FreeBridgin.html
#define CASE(cftype, foundationClass)                         \
if (strcmp(typeEncoding, @encode(cftype)) == 0) {         \
return [value isKindOfClass:[foundationClass class]]; \
}

    CASE(CFArrayRef, NSArray);
    CASE(CFAttributedStringRef, NSAttributedString);
    CASE(CFCalendarRef, NSCalendar);
    CASE(CFCharacterSetRef, NSCharacterSet);
    CASE(CFDataRef, NSData);
    CASE(CFDateRef, NSDate);
    CASE(CFDictionaryRef, NSDictionary);
    CASE(CFErrorRef, NSError);
    CASE(CFLocaleRef, NSLocale);
    CASE(CFMutableArrayRef, NSMutableArray);
    CASE(CFMutableAttributedStringRef, NSMutableAttributedString);
    CASE(CFMutableCharacterSetRef, NSMutableCharacterSet);
    CASE(CFMutableDataRef, NSMutableData);
    CASE(CFMutableDictionaryRef, NSMutableDictionary);
    CASE(CFMutableSetRef, NSMutableSet);
    CASE(CFMutableStringRef, NSMutableString);
    CASE(CFNumberRef, NSNumber);
    CASE(CFReadStreamRef, NSInputStream);
    CASE(CFRunLoopTimerRef, NSTimer);
    CASE(CFSetRef, NSSet);
    CASE(CFStringRef, NSString);
    CASE(CFTimeZoneRef, NSTimeZone);
    CASE(CFURLRef, NSURL);
    CASE(CFWriteStreamRef, NSOutputStream);

#undef CASE

    return NO;
}

+ (NSValue *)valueForPrimitivePointer:(void *)pointer objCType:(const char *)type
{
    // Remove the field name if there is any (e.g. \"width\"d -> d)
    const NSUInteger fieldNameOffset = [CCCookieManager fieldNameOffsetForTypeEncoding:type];
    if (fieldNameOffset > 0) {
        return [self valueForPrimitivePointer:pointer objCType:type + fieldNameOffset];
    }

    // CASE macro inspired by https://www.mikeash.com/pyblog/friday-qa-2013-02-08-lets-build-key-value-coding.html
#define CASE(ctype, selectorpart)                                     \
if (strcmp(type, @encode(ctype)) == 0) {                          \
return [NSNumber numberWith##selectorpart:*(ctype *)pointer]; \
}

    CASE(BOOL, Bool);
    CASE(unsigned char, UnsignedChar);
    CASE(short, Short);
    CASE(unsigned short, UnsignedShort);
    CASE(int, Int);
    CASE(unsigned int, UnsignedInt);
    CASE(long, Long);
    CASE(unsigned long, UnsignedLong);
    CASE(long long, LongLong);
    CASE(unsigned long long, UnsignedLongLong);
    CASE(float, Float);
    CASE(double, Double);
    CASE(long double, Double);

#undef CASE

    NSValue *value = nil;
    @try {
        value = [NSValue valueWithBytes:pointer objCType:type];
    } @catch (NSException *exception) {
        // Certain type encodings are not supported by valueWithBytes:objCType:. Just fail silently if an exception is thrown.
    }

    return value;
}

+ (NSUInteger)fieldNameOffsetForTypeEncoding:(const CCTypeEncoding *)typeEncoding
{
    NSUInteger beginIndex = 0;
    while (typeEncoding[ beginIndex ] == CCTypeEncodingQuote) {
        NSUInteger endIndex = beginIndex + 1;
        while (typeEncoding[ endIndex ] != CCTypeEncodingQuote) {
            ++endIndex;
        }
        beginIndex = endIndex + 1;
    }
    return beginIndex;
}

@end
