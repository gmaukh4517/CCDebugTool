//
//  CCTouchWindow.h
//  CCDebugTool
//
//  Created by CC on 2019/11/11.
//  Copyright © 2019 CC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CCTouchWindow : UIWindow

- (void)displayEvent:(UIEvent *)event;

- (void)destroy ;

@end
