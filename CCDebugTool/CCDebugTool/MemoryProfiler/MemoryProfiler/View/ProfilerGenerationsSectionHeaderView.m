//
//  ProfilerGenerationsSectionHeaderView.m
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

#import "ProfilerGenerationsSectionHeaderView.h"

@interface ProfilerGenerationsSectionHeaderView ()

@property (nonatomic, strong) UIButton *retainCycleButton;
@property (nonatomic, strong) UIButton *collapseButton;

@end

@implementation ProfilerGenerationsSectionHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        [self initialization];
    }
    return self;
}

- (void)initialization
{
    UIButton *retainCycleButton = [self defaultSectionButton];
    [retainCycleButton setTitle:@"Retain Cycles" forState:UIControlStateNormal];
    [retainCycleButton addTarget:self action:@selector(retainCycleDetectionButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *collapseButton = [self defaultSectionButton];
    [collapseButton addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:_retainCycleButton = retainCycleButton];
    [self addSubview:_collapseButton = collapseButton];
}

- (void)buttonTapped
{
    if ([self.delegate respondsToSelector:@selector(sectionHeaderRequestedExpandCollapseAction:)])
        [self.delegate sectionHeaderRequestedExpandCollapseAction:self];
}

- (void)retainCycleDetectionButtonTapped
{
    if ([self.delegate respondsToSelector:@selector(sectionHeaderRequestedRetainCycleDetection:)])
        [self.delegate sectionHeaderRequestedRetainCycleDetection:self];
}

- (UIButton *)defaultSectionButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.titleLabel.font = [UIFont systemFontOfSize:10];
    button.layer.borderColor = [UIColor lightGrayColor].CGColor;
    button.layer.borderWidth = 1.0;
    
    return button;
}

- (void)setExpanded:(BOOL)expanded
{
    _expanded = expanded;
    
    if (_expanded) {
        [_collapseButton setTitle:@"Collapse" forState:UIControlStateNormal];
    } else {
        [_collapseButton setTitle:@"Expand" forState:UIControlStateNormal];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat expandButtonWidth = 56.0;
    CGFloat retainCyclesButtonWidth = 70.0;
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat margin = 2.0;
    CGFloat height = CGRectGetHeight(self.bounds) - 2 * margin;
    
    CGRect frame = self.textLabel.frame;
    frame.origin.y = (CGRectGetHeight(self.bounds) - frame.size.height) / 2;
    self.textLabel.frame = frame;
    
    _retainCycleButton.frame = CGRectMake(width - expandButtonWidth - retainCyclesButtonWidth - 4 * margin,
                                          margin,
                                          retainCyclesButtonWidth,
                                          height);
    
    _collapseButton.frame = CGRectMake(width - expandButtonWidth - 2 * margin,
                                       margin,
                                       expandButtonWidth,
                                       height);
}


@end
