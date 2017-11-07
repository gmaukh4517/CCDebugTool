//
//  CCFilePathTreeView.h
//  CCDebugTool
//
//  Created by CC on 2017/11/3.
//  Copyright © 2017年 CC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCSandboxEntity.h"

@protocol CCFilePathTreeViewDelegate <NSObject>

@required

- (void)filePathTreeViewDidSelectItem:(CCSandboxEntity *)item;

@end

@interface CCFilePathTreeView : UIView

/** 当前文件夹路径节点记录 */
@property(nonatomic, strong) NSMutableArray *pathNodeArray;
/** 代理 */
@property (nonatomic, weak) id<CCFilePathTreeViewDelegate> delegate;

/** 刷新视图 */
- (void)refreshView;

@end
