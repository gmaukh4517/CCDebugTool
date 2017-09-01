//
//  ProfilerTableHeader.m
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

#import "ProfilerTableHeader.h"

@implementation ProfilerTableHeader

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initialization];
    }
    return self;
}

- (void)initialization
{
    UIView *fieldView = [[UIView alloc] initWithFrame:CGRectMake(10, 5, self.frame.size.width - 130, 25)];
    fieldView.backgroundColor = [UIColor whiteColor];
    fieldView.layer.borderWidth = 0.5;
    fieldView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [self addSubview:fieldView];
    
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(5, 0, fieldView.frame.size.width, fieldView.frame.size.height)];
    textField.font = [UIFont systemFontOfSize:14];
    textField.placeholder = @"Filter...";
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [fieldView addSubview:textField];
    
    UIButton *markGenerationButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    markGenerationButton.frame = CGRectMake(fieldView.frame.origin.x + fieldView.frame.size.width + 10, fieldView.frame.origin.y, 100, 25);
    markGenerationButton.backgroundColor = [UIColor whiteColor];
    markGenerationButton.layer.borderWidth = 1.0;
    markGenerationButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [markGenerationButton setTitle:@"Mark Gen." forState:UIControlStateNormal];
    [markGenerationButton addTarget:self action:@selector(markGenerationClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:markGenerationButton];
    
    UISegmentedControl *sortControl = [[UISegmentedControl alloc] initWithItems:@[ @"Class", @"Alive", @"Size", @"Cycle" ]];
    sortControl.selectedSegmentIndex = 0;
    sortControl.frame = CGRectMake(fieldView.frame.origin.x, fieldView.frame.origin.y + fieldView.frame.size.height + 7, 200, fieldView.frame.size.height);
    [sortControl addTarget:self action:@selector(sortControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:sortControl];
}

- (void)markGenerationClick:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(markGeneration)])
        [self.delegate markGeneration];
}

- (void)sortControlValueChanged:(UISegmentedControl *)sender
{
    if ([self.delegate respondsToSelector:@selector(sortValueChanged:)])
        [self.delegate sortValueChanged:sender];
}

- (void)textFieldDidChange:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(textFieldDidChange:)]) {
        [self.delegate textFieldDidChange:textField.text];
    }
}

@end
