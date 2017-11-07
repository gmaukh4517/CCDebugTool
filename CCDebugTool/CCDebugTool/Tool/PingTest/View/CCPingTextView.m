//
//  CCPingTextView.m
//  CCDebugTool
//
//  Created by CC on 2017/11/3.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCPingTextView.h"

@implementation CCPingTextView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        self.textColor = [UIColor greenColor];
        
        if ([self respondsToSelector:@selector(layoutManager)])
            self.layoutManager.allowsNonContiguousLayout = NO;

        self.font = [UIFont systemFontOfSize:14];
        self.editable = NO;
    }
    return self;
}

- (void)appendText:(NSString *)text
{
    if (text.length == 0)
        return;
    
    if (self.text.length == 0){
        self.text = text;
    }else{
        self.text = [NSString stringWithFormat:@"%@\n%@" , self.text, text];
        [self scrollToBottomAnimated:YES];
    }
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    NSInteger height = self.contentSize.height + self.contentInset.bottom - self.bounds.size.height;
    if (height < 0)
        height = 0;
    
    [self setContentOffset:CGPointMake(0.0f, height) animated:animated];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    NSString *selectorName = NSStringFromSelector(action);
    return [selectorName hasPrefix:@"copy"] || [selectorName hasPrefix:@"select"];
}


@end
