//
//  CCMonitorLabel.m
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

#import "CCMonitorLabel.h"

@interface CCMonitorLabel ()

@property (nonatomic, strong) NSMutableDictionary *configCache;

@end

@implementation CCMonitorLabel


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization
{
    [self setTextColor:[UIColor colorWithRed:244.0 / 255.0 green:66.0 / 255.0 blue:66.0 / 255.0 alpha:1.0] forState:CCPerformanceStateBad];
    [self setTextColor:[UIColor orangeColor] forState:CCPerformanceStateWarning];
    [self setTextColor:[UIColor colorWithRed:66.0 / 255.0 green:244.0 / 255.0 blue:89.0 / 255.0 alpha:1.0] forState:CCPerformanceStateGood];
    self.state = CCPerformanceStateGood;
}

- (NSMutableDictionary *)configCache
{
    if (_configCache == nil) {
        _configCache = [[NSMutableDictionary alloc] init];
    }
    return _configCache;
}
- (void)setTextColor:(UIColor *)textColor forState:(CCPerformanceLabelState)state
{
    if (textColor) {
        [self.configCache setObject:textColor forKey:@(state)];
    } else {
        [self.configCache removeObjectForKey:@(state)];
    }
}

- (UIColor *)textColorForState:(CCPerformanceLabelState)state
{
    return [self.configCache objectForKey:@(state)];
}

- (void)setState:(CCPerformanceLabelState)state
{
    _state = state;
    UIColor *color = [self textColorForState:state];
    self.textColor = color;
}


@end
