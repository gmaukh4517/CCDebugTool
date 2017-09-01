//
//  RetainCycleAnalysisCache.m
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

#import "RetainCycleAnalysisCache.h"

@interface RetainCycleAnalysisCache ()

@property (nonatomic, strong) NSMutableArray *analysis;

@end

@implementation RetainCycleAnalysisCache

- (instancetype)init
{
    if (self = [super init]) {
        _analysis = [NSMutableArray new];
    }
    
    return self;
}

- (CCRetainCycleStatus)statusInGeneration:(NSUInteger)generationIndex
                            forClassNamed:(NSString *)className
{
    if (_analysis.count <= generationIndex || (_analysis[generationIndex][className] == nil)) {
        return CCRetainCycleUnknown;
    }
    
    return (CCRetainCycleStatus)[_analysis[generationIndex][className] unsignedIntegerValue];
}

- (void)updateAnalysisStatus:(CCRetainCycleStatus)status
             forInGeneration:(NSUInteger)generationIndex
               forClassNamed:(NSString *)className
{
    // If first class in new generation, expand array
    while (_analysis.count <= generationIndex) {
        [_analysis addObject:[NSMutableDictionary new]];
    }
    
    [_analysis[generationIndex] setObject:@(status) forKey:className];
}


@end
