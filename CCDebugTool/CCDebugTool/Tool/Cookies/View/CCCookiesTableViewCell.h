//
//  CookiesTableViewCell.h
//  CCDebugTool
//
//  Created by CC on 2017/11/21.
//  Copyright © 2017年 CC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CCCookiesTableViewCell : UITableViewCell

-(void)cc_cellWillDisplayWithModel:(NSHTTPCookie *)entity;

@end
