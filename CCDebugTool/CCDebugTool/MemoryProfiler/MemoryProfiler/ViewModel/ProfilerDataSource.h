//
//  ProfilerDataSource.h
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
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CCMemoryProfilerSortingMode) {
    CCMemoryProfilerSortByClass,
    CCMemoryProfilerSortByAlive,
    CCMemoryProfilerSortBySize,
    CCMemoryProfilerSortByCycle
};

typedef NS_ENUM(NSUInteger, CCMemoryProfilerSortingOrder) {
    CCMemoryProfilerSortingOrderAscending,
    CCMemoryProfilerSortingOrderDescending,
};

@interface ProfilerDataSource : NSObject <UITableViewDataSource>

/**
 classFilter is a string representing part of class name, used to filter data by class name
 */
@property (nonatomic, copy, nullable) NSString *classFilter;

/**
 What mode is used to sort data in table view? Check FBMemoryProfilerSortingMode
 */
@property (nonatomic, assign) CCMemoryProfilerSortingMode sortingMode;

/**
 Is data in ascending or descending order?
 */
@property (nonatomic, assign) CCMemoryProfilerSortingOrder sortingOrder;

/**
 @param analysisCache is a cache of results memory profiler gathered during retain cycle detection. Rows which objects
 were checked for retain cycles will be marked with red or green depending on wether they were cycled or no
 */
- (nonnull instancetype)initWithAnalysisCache:(nullable RetainCycleAnalysisCache *)analysisCache;

/**
 In Generations mode full section can be expanded or collapsed to make it easier to browse
 */
- (void)setExpanded:(BOOL)expanded forSection:(NSInteger)section;

/**
 Checks if current section is expanded
 */
- (BOOL)isSectionExpanded:(NSInteger)section;

/**
 Summary for section will be a string that will appear next to generation name.
 */
- (nonnull NSString *)summaryForSection:(NSInteger)section;

/**
 If we need new data, because we for example marked new generation, we can force refresh.
 */
- (void)forceDataReload;

/**
 Takes visible cells and returns an array of class names that those cells represent.
 */
- (nonnull NSArray<NSString *> *)classNamesForSection:(NSInteger)section;

@end
