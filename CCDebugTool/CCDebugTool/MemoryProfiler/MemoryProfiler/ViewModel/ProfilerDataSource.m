//
//  ProfilerDataSource.m
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

#import "ProfilerDataSource.h"
#import "FBAllocationTrackerManager.h"
#import "FBAllocationTrackerSummary.h"

static NSString *const kCCMemoryProfilerCellIdentifier = @"kCCMemoryProfilerCellIdentifier";

static UIColor *CCMemoryProfilerPaleGreenColor()
{
    return [UIColor colorWithRed:198 / 255.0 green:1.0 blue:197 / 255.0 alpha:1.0];
}

static UIColor *CCMemoryProfilerPaleRedColor()
{
    return [UIColor colorWithRed:1.0 green:196 / 255.0 blue:197 / 255.0 alpha:1.0];
}

@interface ProfilerDataSource ()

@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) NSArray *filtered;

// If section should be collapsed it's index will be in that set
@property (nonatomic, strong) NSMutableSet *expandedSection;

@property (nonatomic, strong) NSByteCountFormatter *byteCountFormatter;

@property (nonatomic, strong) RetainCycleAnalysisCache *analysisCache;

@end

@implementation ProfilerDataSource

- (instancetype)initWithAnalysisCache:(RetainCycleAnalysisCache *)analysisCache
{
    if (self = [super init]) {
        _expandedSection = [NSMutableSet new];
        _byteCountFormatter = [NSByteCountFormatter new];
        _analysisCache = analysisCache;
    }
    return self;
}

- (void)setExpanded:(BOOL)expanded
         forSection:(NSInteger)section
{
    if (expanded) {
        [_expandedSection addObject:@(section)];
    } else {
        [_expandedSection removeObject:@(section)];
    }
}

- (BOOL)isSectionExpanded:(NSInteger)section
{
    return [_expandedSection containsObject:@(section)];
}

- (void)forceDataReload
{
    if (![[FBAllocationTrackerManager sharedManager] isAllocationTrackerEnabled])
        return;
    
    _data = [[FBAllocationTrackerManager sharedManager] currentSummaryForGenerations];
    [self refilter];
}

- (UIColor *)colorForAnalysisStatus:(CCRetainCycleStatus)status
{
    switch (status) {
        case CCRetainCycleUnknown:
            return [UIColor whiteColor];
        case CCRetainCycleNotPresent:
            return CCMemoryProfilerPaleGreenColor();
        case CCRetainCyclePresent:
            return CCMemoryProfilerPaleRedColor();
    }
}

- (NSString *)summaryForSection:(NSInteger)section
{
    NSInteger summary = 0;
    NSInteger bytes = 0;
    
    for (FBAllocationTrackerSummary *entry in _data[section]) {
        NSInteger alive = entry.aliveObjects;
        summary += alive;
        bytes += (alive * entry.instanceSize);
    }
    
    return [NSString stringWithFormat:@"%ld (%@)",
            (long)summary,
            [_byteCountFormatter stringFromByteCount:bytes]];
}

- (void)setClassFilter:(NSString *)classFilter
{
    _classFilter = [classFilter lowercaseString];
    
    if (_classFilter.length == 0) {
        _classFilter = nil;
    }
    
    [self refilter];
}

- (void)setSortingMode:(CCMemoryProfilerSortingMode)sortingMode
{
    BOOL sortingModeChanged = sortingMode != _sortingMode;
    _sortingMode = sortingMode;
    
    if (sortingModeChanged) {
        [self refilter];
    }
}

- (void)setSortingOrder:(CCMemoryProfilerSortingOrder)sortingOrder
{
    BOOL sortingOrderChanged = sortingOrder != _sortingOrder;
    _sortingOrder = sortingOrder;
    
    if (sortingOrderChanged) {
        [self refilter];
    }
}

- (NSArray *)_refilterSectionAtIndex:(NSInteger)index
{
    NSArray *filtered = [_data[index] filteredArrayUsingPredicate:
                         [NSPredicate predicateWithBlock:^BOOL(FBAllocationTrackerSummary *entry, NSDictionary *bindings) {
        NSInteger alive = entry.aliveObjects;
        NSInteger byteCount = alive * entry.instanceSize;
        entry.byteCount = [_byteCountFormatter stringFromByteCount:byteCount];
        entry.status = [_analysisCache statusInGeneration:index
                                            forClassNamed:entry.className];
        entry.color = [self colorForAnalysisStatus:entry.status];
        
        NSString *className = entry.className.lowercaseString;
        if (_classFilter && [className rangeOfString:_classFilter].location == NSNotFound) {
            return NO;
        }
        
        if (entry.aliveObjects > 0 && entry.className) {
            return YES;
        }
        
        return NO;
    }]];
    
    switch (_sortingMode) {
        case CCMemoryProfilerSortByCycle:
            filtered = [self _sortArray:filtered withKey:@"status" sortAscending:NO];
            break;
        case CCMemoryProfilerSortByClass:
            filtered = [self _sortArray:filtered withKey:@"className" sortAscending:YES];
            break;
        case CCMemoryProfilerSortByAlive:
            filtered = [self _sortArray:filtered withKey:@"aliveObjects" sortAscending:NO];
            break;
        case CCMemoryProfilerSortBySize:
            filtered = [filtered sortedArrayUsingComparator:^NSComparisonResult(FBAllocationTrackerSummary *obj1,
                                                                                FBAllocationTrackerSummary *obj2) {
                NSUInteger size1 = obj1.aliveObjects * obj1.instanceSize;
                NSUInteger size2 = obj2.aliveObjects * obj2.instanceSize;
                if (size1 > size2) {
                    return (_sortingOrder == CCMemoryProfilerSortingOrderAscending) ? NSOrderedDescending : NSOrderedAscending;
                } else if (size2 > size1) {
                    return (_sortingOrder == CCMemoryProfilerSortingOrderAscending) ? NSOrderedAscending : NSOrderedDescending;
                } else {
                    return NSOrderedSame;
                }
            }];
            break;
    }
    
    return filtered;
}

- (NSArray *)_sortArray:(NSArray *)array withKey:(NSString *)key sortAscending:(BOOL)sortAscending
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:key
                                                           ascending:sortAscending];
    return [array sortedArrayUsingDescriptors:@[ sort ]];
}

- (void)refilter
{
    NSMutableArray *filtered = [NSMutableArray array];
    for (NSInteger i = 0; i < _data.count; ++i) {
        [filtered addObject:[self _refilterSectionAtIndex:i]];
    }
    
    _filtered = filtered;
}

- (NSArray<NSString *> *)classNamesForSection:(NSInteger)section
{
    NSMutableArray *array = [NSMutableArray new];
    
    for (FBAllocationTrackerSummary *object in _filtered[section]) {
        [array addObject:object.className];
    }
    
    return array;
}

#pragma mark -
#pragma mark :. UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_filtered count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (![self isSectionExpanded:section]) {
        return 0;
    }
    return [_filtered[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCCMemoryProfilerCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kCCMemoryProfilerCellIdentifier];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
        cell.detailTextLabel.textColor = [UIColor blackColor];
        cell.textLabel.font = [UIFont systemFontOfSize:13];
        cell.textLabel.textColor = [UIColor grayColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    FBAllocationTrackerSummary *row = _filtered[indexPath.section][indexPath.row];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%zi (%@)", row.aliveObjects, row.byteCount];
    cell.textLabel.text = row.className;
    cell.backgroundColor = row.color;
    
    return cell;
}

@end
