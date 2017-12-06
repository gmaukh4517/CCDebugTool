//
//  LeftDatabaseView.h
//  CCDebugTool
//
//  Created by CC on 2017/12/6.
//  Copyright © 2017年 CC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LeftDatabaseViewDelegate <NSObject>
@required

- (void)didDatabaseClick:(NSString *)databasePath;
- (void)didTableClick:(NSString *)tableName;

@end

@interface LeftDatabaseView : UIView

@property (nonatomic, weak) id<LeftDatabaseViewDelegate> delegate;

- (void)fillDatabase:(NSArray *)arr;

- (void)fillTable:(NSArray *)arr;

@end
