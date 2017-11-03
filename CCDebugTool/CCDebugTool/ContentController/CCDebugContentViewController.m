//
//  CCDebugContentViewController.m
//  CCKit
//
// Copyright (c) 2015 CC ( https://github.com/gmaukh4517/CCKit )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "CCDebugContentViewController.h"

@interface CCDebugContentViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation CCDebugContentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initNavigation];
    [self initControl];
}

- (void)initNavigation
{
    if (!self.data)
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"复制" style:UIBarButtonItemStyleDone target:self action:@selector(copyAction:)];
}

- (void)initControl
{
    if (self.dataArr) {
        UIScrollView *scrollview = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        scrollview.pagingEnabled = YES;
        scrollview.showsHorizontalScrollIndicator = NO;
        scrollview.showsVerticalScrollIndicator = NO;
//        scrollview.bounces = NO;
        scrollview.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        scrollview.delegate = self;
        scrollview.contentSize = CGSizeMake(scrollview.frame.size.width * self.dataArr.count, 0);
        [self.view addSubview:_scrollView = scrollview];
        
        if (@available(iOS 11.0, *)) {
            scrollview.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        CGRect frame = CGRectMake(0, 0, scrollview.frame.size.width, scrollview.frame.size.height - 64);
        for (NSInteger i = 0; i < self.dataArr.count; i++) {
            NSDictionary *dataDic = [self.dataArr objectAtIndex:i];
            
            UITextView *contentViewText = [[UITextView alloc] initWithFrame:frame];
            [contentViewText setEditable:NO];
            contentViewText.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
            contentViewText.font = [UIFont systemFontOfSize:13];
            contentViewText.text = [dataDic objectForKey:@"ErrMsg"];
            contentViewText.tag = 100 + i;
            [scrollview addSubview:contentViewText];
            
            if (i == self.selectedIndex) {
                self.title = [dataDic objectForKey:@"ErrDate"];
            }
            
            frame.origin.x += frame.size.width;
        }
        
        CGPoint offset = scrollview.contentOffset;
        offset.x = scrollview.frame.size.width * self.selectedIndex;
        scrollview.contentOffset = offset;
    } else if (self.content) {
        UITextView *contentViewText = [[UITextView alloc] initWithFrame:self.view.bounds];
        [contentViewText setEditable:NO];
        contentViewText.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        contentViewText.font = [UIFont systemFontOfSize:13];
        contentViewText.text = self.content;
        contentViewText.tag = 100;
        [self.view addSubview:contentViewText];
    } else if (self.data) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.image = [UIImage imageWithData:self.data];
        [self.view addSubview:imageView];
    }
}

- (void)copyAction:(UIBarButtonItem *)sender
{
    UITextView *contentTextView = (UITextView *)[self.view viewWithTag:100 + self.selectedIndex];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [contentTextView.text copy];
    
    self.content = contentTextView.text;
    contentTextView.text = [NSString stringWithFormat:@"%@\n\n%@", @"复制成功！", self.content];
    
    __weak typeof(contentTextView) weakTxt = contentTextView;
    __weak typeof(self) wSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakTxt.text = wSelf.content;
    });
}

#pragma mark -
#pragma mark :. UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([scrollView isEqual:self.scrollView]) {
        CGFloat x = scrollView.contentOffset.x;
        NSInteger selectIndex = x / scrollView.frame.size.width;
        self.selectedIndex = selectIndex;
        NSString *title = [[self.dataArr objectAtIndex:selectIndex] objectForKey:@"ErrDate"];
        self.title = title;
        //        [self reloadData:selectIndex];
    }
}

@end
