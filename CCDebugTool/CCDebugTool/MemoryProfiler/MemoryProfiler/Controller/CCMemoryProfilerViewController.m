//
//  CCMemoryProfilerViewController.m
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

#import "CCMemoryProfilerViewController.h"
#import "FBAllocationTrackerManager.h"
#import "FBObjectGraphConfiguration.h"
#import "FBRetainCycleDetector.h"
#import "ProfilerDataSource.h"
#import "ProfilerGenerationsSectionHeaderView.h"
#import "ProfilerTableHeader.h"
#import "RetainCycleAnalysisCache.h"

#import "CCRetainCyclePresenter.h"


static const CGFloat kCCMemoryProfilerRefreshIntervalInSeconds = 3.0;
static NSString *const kProfilerSectionHeaderIdentifier = @"kProfilerSectionHeaderIdentifier";

@interface CCMemoryProfilerViewController () <UITableViewDelegate, ProfilerSectionHeaderDelegate, ProfilerTableHeaderDelegate>

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) UITableView *profilerTableView;
@property (nonatomic, strong) ProfilerTableHeader *tableViewHeader;

@property (nonatomic, strong) ProfilerDataSource *dataSource;
@property (nonatomic, strong) RetainCycleAnalysisCache *analysisCache;

@property (nonatomic, assign) CCMemoryProfilerSortingMode sortingMode;
@property (nonatomic, assign) CCMemoryProfilerSortingOrder sortingOrder;

@end

@implementation CCMemoryProfilerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _analysisCache = [RetainCycleAnalysisCache new];
    _dataSource = [[ProfilerDataSource alloc] initWithAnalysisCache:_analysisCache];
    
    [self initNavigation];
    [self initControl];
    [self initLoadData];
}

- (void)initNavigation
{
    self.title = @"Cycle";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(dismissViewController)];
}

- (void)dismissViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:kCCMemoryProfilerRefreshIntervalInSeconds
                                              target:self
                                            selector:@selector(_loadDataFromTimer:)
                                            userInfo:nil
                                             repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_timer invalidate];
}

- (void)_loadDataFromTimer:(NSTimer *)timer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initLoadData];
    });
}

- (void)initControl
{
    self.profilerTableView.delegate = self;
    self.profilerTableView.dataSource = _dataSource;
    [self.view addSubview:self.profilerTableView];
    
    _tableViewHeader = [[ProfilerTableHeader alloc] initWithFrame:CGRectMake(0, 0, self.profilerTableView.frame.size.width, 70)];
    _tableViewHeader.delegate = self;
    self.profilerTableView.tableHeaderView = _tableViewHeader;
}

- (void)initLoadData
{
    [_dataSource forceDataReload];
    [self.profilerTableView reloadData];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(nonnull UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

- (CGFloat)tableView:(nonnull UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 24.0;
}

- (UIView *)tableView:(nonnull UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    ProfilerGenerationsSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kProfilerSectionHeaderIdentifier];
    
    if (!headerView) {
        headerView = [[ProfilerGenerationsSectionHeaderView alloc] initWithReuseIdentifier:kProfilerSectionHeaderIdentifier];
        headerView.delegate = self;
    }
    
    headerView.expanded = [_dataSource isSectionExpanded:section];
    headerView.index = section;
    headerView.textLabel.text = [NSString stringWithFormat:@"Gen %zi - %@", (long)(section + 1), [_dataSource summaryForSection:section]];
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Retain cycle detection kicks in
    NSString *className = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    NSInteger generationIndex = indexPath.section;
    
    [self _findRetainCyclesForClassesNamed:@[ className ]
                              inGeneration:generationIndex
                            presentDetails:YES];
}

#pragma mark -
#pragma mark :. ProfilerTableHeaderDelegate

- (void)markGeneration
{
    [[FBAllocationTrackerManager sharedManager] markGeneration];
    [self initLoadData];
}

- (void)sortValueChanged:(UISegmentedControl *)sortControl
{
    CCMemoryProfilerSortingMode mode = (CCMemoryProfilerSortingMode)sortControl.selectedSegmentIndex;
    if (mode != _sortingMode) {
        _sortingMode = mode;
        _dataSource.sortingMode = mode;
        _dataSource.sortingOrder = _sortingOrder;
    } else {
        // Mode was the same, we are changing the ordering
        CCMemoryProfilerSortingOrder order = (_sortingOrder == CCMemoryProfilerSortingOrderAscending) ? CCMemoryProfilerSortingOrderDescending : CCMemoryProfilerSortingOrderAscending;
        _sortingOrder = order;
        
        _dataSource.sortingOrder = order;
        _dataSource.sortingMode = _sortingMode;
    }
    [self.profilerTableView reloadData];
}

- (void)textFieldDidChange:(NSString *)text
{
    _dataSource.classFilter = text;
    [self.profilerTableView reloadData];
}

#pragma mark -
#pragma mark :. ProfilerSectionHeaderDelegate

- (void)sectionHeaderRequestedExpandCollapseAction:(ProfilerGenerationsSectionHeaderView *)sectionHeader
{
    sectionHeader.expanded = !sectionHeader.expanded;
    
    [_dataSource setExpanded:sectionHeader.expanded
                  forSection:sectionHeader.index];
    [self.profilerTableView reloadSections:[NSIndexSet indexSetWithIndex:sectionHeader.index] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)sectionHeaderRequestedRetainCycleDetection:(ProfilerGenerationsSectionHeaderView *)sectionHeader
{
    NSArray<NSString *> *classNames = [_dataSource classNamesForSection:sectionHeader.index];
    [self _findRetainCyclesForClassesNamed:classNames
                              inGeneration:sectionHeader.index
                            presentDetails:NO];
}

- (void)_findRetainCyclesForClassesNamed:(NSArray<NSString *> *)classesNamed
                            inGeneration:(NSUInteger)generationIndex
                          presentDetails:(BOOL)presentDetails
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSString *className in classesNamed) {
            Class aCls = NSClassFromString(className);
            NSArray *objects = [[FBAllocationTrackerManager sharedManager] instancesForClass:aCls
                                                                                inGeneration:generationIndex];
            FBObjectGraphConfiguration *configuration = [FBObjectGraphConfiguration new];
            FBRetainCycleDetector *detector = [[FBRetainCycleDetector alloc] initWithConfiguration:configuration];
            
            for (id object in objects)
                [detector addCandidate:object];
            
            NSSet<NSArray<FBObjectiveCGraphElement *> *> *retainCycles = [detector findRetainCyclesWithMaxCycleLength:8];
            
            if ([retainCycles count] > 0) {
                // We've got a leak
                [_analysisCache updateAnalysisStatus:CCRetainCyclePresent
                                     forInGeneration:generationIndex
                                       forClassNamed:className];
                if (presentDetails) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        CCRetainCyclePresenter *cyclePressenter = [[CCRetainCyclePresenter alloc] init];
                        cyclePressenter.retainCycles = [retainCycles allObjects];
                        [self.navigationController pushViewController:cyclePressenter animated:YES];
                        
                    });
                }
            } else {
                [_analysisCache updateAnalysisStatus:CCRetainCycleNotPresent
                                     forInGeneration:generationIndex
                                       forClassNamed:className];
            }
        }
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark :. getter/setter

- (UITableView *)profilerTableView
{
    if (!_profilerTableView) {
        _profilerTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor clearColor];
        [_profilerTableView setTableFooterView:v];
    }
    return _profilerTableView;
}

@end
