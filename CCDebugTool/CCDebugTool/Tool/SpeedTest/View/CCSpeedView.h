//
//  CCSpeedView.h
//  CCDebugTool
//
//  Created by CC on 2017/11/7.
//  Copyright © 2017年 CC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CCSpeedView : UIView

@property (nonatomic, copy) NSString *speed;
@property (nonatomic, copy) NSString *unit;
@property (nonatomic, assign) float speedProgress;

@end
