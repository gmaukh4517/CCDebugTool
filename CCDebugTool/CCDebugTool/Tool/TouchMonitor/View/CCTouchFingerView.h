//
//  CCTouchFingerView.h
//  CCDebugTool
//
//  Created by CC on 2019/11/11.
//  Copyright © 2019 CC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CCTouchFingerView : UIView

- (id)initWithPoint:(CGPoint)point;

- (void)updateWithTouch:(UITouch *)touch;

- (void)removeFromSuperviewWithAnimation;

@end
