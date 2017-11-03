//
//  SandboxCollectionViewCell.h
//  CCDebugTool
//
//  Created by CC on 2017/11/3.
//  Copyright © 2017年 CC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SandboxEntity.h"

@interface SandboxCollectionViewCell : UICollectionViewCell

-(void)cc_cellWillDisplayWithModel:(SandboxEntity *)entity isSelected:(BOOL)selected;

@end
