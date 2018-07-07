//
//  UIViewController+CCDebug.m
//  CCDebugTool
//
//  Created by CC on 2018/7/7.
//  Copyright © 2018年 CC. All rights reserved.
//

#import "UIViewController+CCDebug.h"

@implementation UIViewController (CCDebug)

- (void)pushNewViewController:(UIViewController *)newViewController
{
    self.navigationController.topViewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
    [self.navigationController pushViewController:newViewController animated:YES];
}


@end
