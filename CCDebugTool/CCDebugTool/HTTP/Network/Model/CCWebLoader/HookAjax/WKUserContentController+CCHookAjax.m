//
//  WKUserContentController+CCHookAjax.m
//  CCDebugTool
//
//  Created by CC on 2019/10/23.
//  Copyright © 2019 CC. All rights reserved.
//

#import "WKUserContentController+CCHookAjax.h"
#import <objc/runtime.h>

@interface CCHookAjaxHandler : NSObject<WKScriptMessageHandler>

@property (nonatomic, weak) WKWebView *wkWebView;

@end

@implementation CCHookAjaxHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    self.wkWebView = message.webView;
    [self requestWithBody:message.body];
}

- (void)requestWithBody:(NSDictionary *)body
{
    id requestID = body[ @"id" ];
    NSString *method = body[ @"method" ];
    id requestData = body[ @"data" ];
    NSDictionary *requestHeaders = body[ @"headers" ];
    NSString *urlString = body[ @"url" ];


    NSURL *URL = [CCHookAjaxHandler URLWithString:urlString baseURL:self.wkWebView.URL];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
    request.HTTPMethod = method.uppercaseString;
    if ([body isKindOfClass:[NSString class]]) {
        request.HTTPBody = [requestData dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([body isKindOfClass:[NSData class]]) {
        request.HTTPBody = requestData;
    } else if ([NSJSONSerialization isValidJSONObject:body]) {
        NSError *err = nil;
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:&err];
    }
    [request setAllHTTPHeaderFields:requestHeaders];

    __weak id wself = self;
    NSURLSessionTask *requestHandlerTask = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                           completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {

        __strong CCHookAjaxHandler *self = wself;
        NSHTTPURLResponse *httpResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]])
            httpResponse = (id)response;

        NSDictionary *allHeaderFields = httpResponse.allHeaderFields;
        NSString *responseString = nil;
        if (data.length > 0)
            responseString = [self responseStringWithData:data charset:allHeaderFields[ @"Content-Type" ]];

        [wself requestCallback:requestID httpCode:httpResponse.statusCode headers:allHeaderFields data:responseString];
    }];
    [requestHandlerTask resume];
}

- (NSString *)responseStringWithData:(NSData *)data charset:(NSString *)charset
{
    NSStringEncoding stringEncoding = NSUTF8StringEncoding;
    /// 对一些国内常见编码进行支持
    charset = charset.lowercaseString;
    if ([charset containsString:@"gb2312"]) {
        stringEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    }
    NSString *responseString = [[NSString alloc] initWithData:data encoding:stringEncoding];
    return responseString;
}

- (void)requestCallback:(id)requestId httpCode:(NSInteger)httpCode headers:(NSDictionary *)headers data:(NSString *)data
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[ @"status" ] = @(httpCode);
    dict[ @"headers" ] = headers;
    if (data.length > 0) {
        dict[ @"data" ] = data;
    }
    NSString *jsonString = nil;
    NSError *err = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&err];
    if (jsonData.length > 0) {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    NSString *jsScript = [NSString stringWithFormat:@"window.cc_realxhr_callback(%@, %@);", requestId, jsonString ?: @"{}"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.wkWebView evaluateJavaScript:jsScript
                         completionHandler:^(id result, NSError *error){

        }];
    });
}

+ (NSURL *)URLWithString:(NSString *)urlString baseURL:(NSURL *)baseURL
{
    if (!urlString.length) {
        return nil;
    }
    if (![urlString containsString:@"://"]) {
        if ([urlString hasPrefix:@"//"]) {
            urlString = [NSString stringWithFormat:@"%@:%@", baseURL.scheme ?: @"http", urlString];
        } else if ([urlString hasPrefix:@"/"]) {
            urlString = [NSString stringWithFormat:@"%@://%@%@", baseURL.scheme ?: @"http", baseURL.host, urlString];
        } else {
            urlString = [NSString stringWithFormat:@"%@://%@", baseURL.scheme ?: @"http", urlString];
        }
    }
    NSURL *URL = [NSURL URLWithString:urlString];
    if (!URL) {
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        URL = [NSURL URLWithString:urlString];
    }
    return URL;
}

@end

@implementation WKUserContentController (CCHookAjax)

static inline void AutomaticWritingSwizzleSelector(Class class, SEL originalSelector, SEL swizzledSelector)
{
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    if (class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

//+ (void)load
//{
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        AutomaticWritingSwizzleSelector([self class], @selector(init), @selector(cc_init));
//        AutomaticWritingSwizzleSelector([self class], NSSelectorFromString(@"dealloc"), @selector(cc_dealloc));
//    });
//}

- (instancetype)cc_init
{
    WKUserContentController *wKUserContentController = [self cc_init];
    [wKUserContentController cc_installHookAjax];
    return wKUserContentController;
}

- (void)cc_dealloc
{
    [self cc_uninstallHookAjax];
}

static const void *CCHookAjaxKey = &CCHookAjaxKey;
- (void)cc_uninstallHookAjax
{
    [self removeScriptMessageHandlerForName:@"HookAJAX"];
    objc_setAssociatedObject(self, CCHookAjaxKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cc_installHookAjax
{
    if ([objc_getAssociatedObject(self, CCHookAjaxKey) boolValue])
        return;

    objc_setAssociatedObject(self, CCHookAjaxKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    CCHookAjaxHandler *handler = [CCHookAjaxHandler new];
    [self addScriptMessageHandler:handler name:@"HookAJAX"];
    [self hookAjaxJS];
}

-(void)hookAjaxJS
{
    NSString *hookAjaxJS = @"(function() {\
        if (window.cc_realxhr) {\
            return\
        }\
        window.cc_realxhr = XMLHttpRequest;\
        var timestamp = new Date().getTime();\
        timestamp = parseInt((timestamp / 1000) % 100000);\
        var global_index = timestamp + 1;\
        var global_map = {};\
        window.cc_realxhr_callback = function(id, message) {\
            var hookAjax = global_map[id];\
            if (hookAjax) {\
                hookAjax.callbackNative(message)\
            }\
            global_map[id] = null\
        };\
        function BaseHookAjax() {}\
        BaseHookAjax.prototype = window.cc_realxhr;\
        function hookAjax() {}\
        hookAjax.prototype = BaseHookAjax;\
        hookAjax.prototype.readyState = 0;\
        hookAjax.prototype.responseText = \"\";\
        hookAjax.prototype.responseHeaders = {};\
        hookAjax.prototype.status = 0;\
        hookAjax.prototype.statusText = \"\";\
        hookAjax.prototype.onreadystatechange = null;\
        hookAjax.prototype.onload = null;\
        hookAjax.prototype.onerror = null;\
        hookAjax.prototype.onabort = null;\
        hookAjax.prototype.open = function() {\
            this.open_arguments = arguments;\
            this.readyState = 1;\
            if (this.onreadystatechange) {\
                this.onreadystatechange()\
            }\
        };\
        hookAjax.prototype.setRequestHeader = function(name, value) {\
            if (!this._headers) {\
                this._headers = {}\
            }\
            this._headers[name] = value\
        };\
        hookAjax.prototype.send = function() {\
            if (arguments.length >= 1 && !!arguments[0]) {\
                this.sendNative(arguments[0])\
            } else {\
                var xhr = new window.cc_realxhr();\
                this._xhr = xhr;\
                var that = this;\
                xhr.onreadystatechange = function() {\
                    that.readyState = xhr.readyState;\
                    if (that.readyState <= 1) {\
                        return\
                    }\
                    if (xhr.readyState >= 3) {\
                        that.status = xhr.status;\
                        that.statusText = xhr.statusText;\
                        that.responseText = xhr.responseText;\
                    }\
                    that.callbackStateChanged();\
                };\
                xhr.open.apply(xhr, this.open_arguments);\
                for (name in this._headers) {\
                    xhr.setRequestHeader(name, this._headers[name])\
                }\
                xhr.send.apply(xhr, arguments)\
            }\
        };\
        hookAjax.prototype.sendNative = function(data) {\
            this.request_id = global_index;\
            global_map[this.request_id] = this;\
            global_index++;\
            var message = {};\
            message.id = this.request_id;\
            message.data = data;\
            message.method = this.open_arguments[0];\
            message.url = this.open_arguments[1];\
            message.headers = this._headers;\
            window.webkit.messageHandlers.HookAJAX.postMessage(message)\
        };\
        hookAjax.prototype.callbackNative = function(message) {\
            if (!this.is_abort) {\
                this.status = message.status;\
                this.responseText = (!!message.data) ? message.data : \"\";\
                this.responseHeaders = message.headers;\
                this.readyState = 4\
            } else {\
                this.readyState = 1\
            }\
            this.callbackStateChanged();\
        };\
        hookAjax.prototype.callbackStateChanged = function() {\
            if (this.readyState >= 3) {\
                if (this.status >= 200 && this.status < 300) {\
                    this.statusText = \"OK\"\
                } else {\
                    this.statusText = \"Fail\"\
                }\
            }\
            if (this.onreadystatechange) {\
                this.onreadystatechange()\
            }\
            if (this.readyState == 4) {\
                if (this.statusText == \"OK\") {\
                    this.onload ? this.onload() : \"\"\
                } else {\
                    this.onerror ? this.onerror() : \"\"\
                }\
            }\
        };\
        hookAjax.prototype.abort = function() {\
            this.is_abort = true;\
            if (this._xhr) {\
                this._xhr.abort()\
            }\
            if (this.onabort) {\
                this.onabort()\
            }\
        };\
        hookAjax.prototype.getAllResponseHeaders = function() {\
            if (this._xhr) {\
                return this._xhr.getAllResponseHeaders()\
            } else {\
                return this.responseHeaders\
            }\
        };\
        hookAjax.prototype.getResponseHeader = function(name) {\
            if (this._xhr) {\
                return this._xhr.getResponseHeader(name)\
            } else {\
                for (key in this.responseHeaders) {\
                    if (key.toLowerCase() == name.toLowerCase()) {\
                        return this.responseHeaders[key]\
                    }\
                }\
                return null\
            }\
        };\
        XMLHttpRequest = hookAjax;\
        window.cc_hookAjax = function() {\
            XMLHttpRequest = hookAjax\
        };\
        window.cc_unhookAjax = function() {\
            XMLHttpRequest = window.cc_realxhr\
        }\
    })();";

    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:hookAjaxJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [self addUserScript:userScript];
}

@end
