//
//  RetainCycleAnalysisCache.h
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

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CCRetainCycleStatus) {
    CCRetainCycleUnknown,
    CCRetainCycleNotPresent,
    CCRetainCyclePresent
};

@interface RetainCycleAnalysisCache : NSObject

/**
 What is the status of retain cycle detection for class in given generation
 
 @param generationIndex generation to check
 @param className class to check
 */
- (CCRetainCycleStatus)statusInGeneration:(NSUInteger)generationIndex
                            forClassNamed:(nullable NSString *)className;

/**
 Sets new state for given class in given generation
 
 @param status new status to set
 @param generationIndex generation to update
 @param className class to update
 */
- (void)updateAnalysisStatus:(CCRetainCycleStatus)status
             forInGeneration:(NSUInteger)generationIndex
               forClassNamed:(nullable NSString *)className;

@end
