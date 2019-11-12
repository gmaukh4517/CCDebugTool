//
//  WKUserContentController+CCHookAjax.h
//  CCDebugTool
//
//  Created by CC on 2019/10/23.
//  Copyright © 2019 CC. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface WKUserContentController (CCHookAjax)
- (void)cc_installHookAjax;
@end
