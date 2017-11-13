//
//  CCHTTPTableViewCell.h
//  CCDebugTool
//
//  Created by CC on 2017/11/9.
//  Copyright © 2017年 CC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCNetworkTransaction.h"

@interface CCHTTPTableViewCell : UITableViewCell

@property (nonatomic, strong) CCNetworkTransaction *transaction;

-(void)cc_cellWillDisplayWithModel:(CCNetworkTransaction *)cModel;

@end
