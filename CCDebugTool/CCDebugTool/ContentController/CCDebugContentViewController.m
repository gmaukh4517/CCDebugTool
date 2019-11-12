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
#import "CCDebugTool.h"
#import "LOGCollectionViewCell.h"
#import <WebKit/WebKit.h>

@interface CCDebugContentViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, WKNavigationDelegate>

@property (nonatomic, strong) UICollectionView *logCollectionView;

@property (nonatomic, weak) WKWebView *webView;

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
        self.logCollectionView.contentSize = CGSizeMake(self.dataArr.count * (self.view.frame.size.width + 10), 0);
        [self.view addSubview:self.logCollectionView];

        NSString *title = [[self.dataArr objectAtIndex:self.selectedIndex] objectForKey:@"ErrDate"];
        if (!title)
            title = [[self.dataArr objectAtIndex:self.selectedIndex] objectForKey:@"fileName"];

        self.title = title;
        [self.logCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
    } else if (self.content) {
        UITextView *contentViewText = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 64)];
        [contentViewText setEditable:NO];
        contentViewText.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        contentViewText.font = [UIFont systemFontOfSize:13];
        contentViewText.text = self.content;
        contentViewText.tag = 100;
        [self.view addSubview:contentViewText];

        if (@available(iOS 11.0, *)) {
            contentViewText.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    } else if (self.data) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 64)];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.image = [UIImage imageWithData:self.data];
        [self.view addSubview:imageView];
    } else if (self.url) {
        self.title = self.url;
        WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
        configuration.dataDetectorTypes = UIDataDetectorTypeLink;
        WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
        webView.navigationDelegate = self;
        webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
        [webView loadRequest:request];
        [self.view addSubview:_webView = webView];
    }
}

- (void)copyAction:(UIBarButtonItem *)sender
{
    UITextView *contentTextView = (UITextView *)[self.view viewWithTag:100 + self.selectedIndex];
    if (contentTextView) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [contentTextView.text copy];

        self.content = contentTextView.text;
        contentTextView.text = [NSString stringWithFormat:@"%@\n\n%@", @"复制成功！", self.content];

        __weak typeof(contentTextView) weakTxt = contentTextView;
        __weak typeof(self) wSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weakTxt.text = wSelf.content;
        });
    } else if (self.url) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = self.url;
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        CGRect frame = obj.frame;
        frame.size.height = self.view.bounds.size.height;
        obj.frame = frame;
        if ([obj isKindOfClass:[UICollectionView class]]) {
            _logCollectionView.contentSize = CGSizeMake(self.dataArr.count * (self.view.bounds.size.width + 10), 0);
            UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)_logCollectionView.collectionViewLayout;
            CGSize size = layout.itemSize;
            size.height = self.view.bounds.size.height;
            layout.itemSize = size;
        }
    }];
}

#pragma mark - WKWebView Delegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    WKNavigationActionPolicy policy = WKNavigationActionPolicyCancel;
    if (navigationAction.navigationType == WKNavigationTypeOther) {
        // Allow the initial load
        policy = WKNavigationActionPolicyAllow;
    } else {
        // For clicked links, push another web view controller onto the navigation stack so that hitting the back button works as expected.
        // Don't allow the current web view to handle the navigation.
        CCDebugContentViewController *viewController = [CCDebugContentViewController new];
        viewController.url = navigationAction.request.URL.absoluteString;
        [self pushCCNewViewController:viewController];
    }
    decisionHandler(policy);
}


#pragma mark -
#pragma mark :. UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([scrollView isEqual:self.logCollectionView]) {
        CGFloat x = scrollView.contentOffset.x;
        NSInteger selectIndex = x / scrollView.frame.size.width;
        self.selectedIndex = selectIndex;

        NSDictionary *dataDic = [self.dataArr objectAtIndex:selectIndex];
        NSString *title = [dataDic objectForKey:@"ErrDate"];
        if (!title)
            title = [dataDic objectForKey:@"fileName"];

        self.title = title;
    }
}

#pragma mark -
#pragma mark :. UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dataDic = [self.dataArr objectAtIndex:indexPath.row];

    NSString *cellIdentifier = @"ErrorCollectionViewCell";
    if ([dataDic objectForKey:@"fileName"])
        cellIdentifier = @"LOGCollectionViewCell";

    UICollectionViewCell *logCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];

    if ([cellIdentifier isEqualToString:@"ErrorCollectionViewCell"]) {
        UITextView *contentViewText = (UITextView *)[logCell viewWithTag:123];
        if (!contentViewText) {
            contentViewText = [[UITextView alloc] initWithFrame:CGRectMake(5, 0, logCell.frame.size.width - 10, logCell.frame.size.height)];
            [contentViewText setEditable:NO];
            contentViewText.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
            contentViewText.font = [UIFont systemFontOfSize:13];
            contentViewText.tag = 123;
            [logCell addSubview:contentViewText];
        }

        contentViewText.text = [dataDic objectForKey:@"ErrMsg"];
    } else {
        [((LOGCollectionViewCell *)logCell) cc_cellWillDisplayWithModel:[dataDic objectForKey:@"dataArr"] indexPath:indexPath];
    }

    return logCell;
}

#pragma mark -
#pragma mark :. getter/setter

- (UICollectionView *)logCollectionView
{
    if (!_logCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(self.view.bounds.size.width + 10, self.view.bounds.size.height - 64);
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

        _logCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(-5, 0, self.view.bounds.size.width + 10, self.view.bounds.size.height - 64) collectionViewLayout:layout];
        _logCollectionView.backgroundColor = [UIColor colorWithRed:0.949 green:0.949 blue:0.949 alpha:1];
        _logCollectionView.dataSource = self;
        _logCollectionView.delegate = self;
        _logCollectionView.pagingEnabled = YES;
        _logCollectionView.scrollsToTop = NO;
        _logCollectionView.showsHorizontalScrollIndicator = NO;
        _logCollectionView.contentOffset = CGPointMake(0, 0);
        [_logCollectionView registerClass:[LOGCollectionViewCell class] forCellWithReuseIdentifier:@"LOGCollectionViewCell"];
        [_logCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"ErrorCollectionViewCell"];

        if (@available(iOS 11.0, *))
            _logCollectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    return _logCollectionView;
}


@end
