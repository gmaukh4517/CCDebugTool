//
//  SandboxTableViewCell.h
//  CCDebugTool
//
//  Created by CC on 2017/11/3.
//  Copyright © 2017年 CC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCSandboxEntity.h"

@interface CCSandboxTableViewCell : UITableViewCell

-(void)cc_cellWillDisplayWithModel:(CCSandboxEntity *)entity;

@end
