//
//  SandboxViewController.m
//  CCDebugTool
//
//  Created by CC on 2017/11/3.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCSandboxViewController.h"
#import "CCSandboxTableViewCell.h"
#import "CCFilePathTreeView.h"
#import "CCSandboxEntity.h"
#import "CCPingViewController.h"
#import "CCSandboxPreviewItem.h"
#import <QuickLook/QuickLook.h>

@interface CCSandboxViewController () <UITableViewDelegate, UITableViewDataSource, CCFilePathTreeViewDelegate, QLPreviewControllerDataSource>

@property (nonatomic, strong) UITableView *sandboxViewTableView;
@property (nonatomic, strong) NSArray *dataArr;
@property (nonatomic, strong) CCFilePathTreeView *filePathView;

@property (nonatomic, strong) QLPreviewController *fileViewerViewController;
@property (nonatomic, strong) NSMutableArray *fileArray;

@end

@implementation CCSandboxViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initNavigation];
    [self initControl];
    [self initLoadData];
}

- (void)initNavigation
{
    self.navigationItem.title = @"沙盒";
}

- (void)initControl
{
    self.view.backgroundColor = [UIColor whiteColor];
    CCFilePathTreeView *filePathView = [[CCFilePathTreeView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 34)];
    filePathView.delegate = self;
    [self.view addSubview:_filePathView = filePathView];

    CGRect TableViewFrame = self.view.bounds;
    TableViewFrame.origin.y = 34;
    TableViewFrame.size.height = self.view.bounds.size.height - 35;

    UITableView *sandboxViewTableView = [[UITableView alloc] initWithFrame:TableViewFrame style:UITableViewStylePlain];
    sandboxViewTableView.backgroundColor = [UIColor clearColor];
    sandboxViewTableView.delegate = self;
    sandboxViewTableView.dataSource = self;
    sandboxViewTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    sandboxViewTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [sandboxViewTableView registerClass:[CCSandboxTableViewCell class] forCellReuseIdentifier:@"CCSandboxTableViewCellIdentifer"];
    [self.view addSubview:_sandboxViewTableView = sandboxViewTableView];

    if (@available(iOS 11.0, *)) {
        sandboxViewTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }

    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.backgroundColor = [UIColor clearColor];
    [sandboxViewTableView setTableFooterView:v];

    _fileViewerViewController = [[QLPreviewController alloc] init];
    _fileViewerViewController.dataSource = self;
}

- (void)initLoadData
{
    _fileArray = [NSMutableArray array];

    [self obtainPathItems:NSHomeDirectory()];
    CCSandboxEntity *entity = [[CCSandboxEntity alloc] init];
    entity.fileName = @"Home";
    entity.filePath = NSHomeDirectory();
    [self.filePathView.pathNodeArray addObject:entity];
    [self.filePathView refreshView];
}

#pragma mark -
#pragma mark :. CJFilePathTreeViewDelegate
- (void)filePathTreeViewDidSelectItem:(CCSandboxEntity *)item
{
    NSInteger index = [self.filePathView.pathNodeArray indexOfObject:item];
    NSRange range = NSMakeRange(index + 1, self.filePathView.pathNodeArray.count - index - 1);
    [self.filePathView.pathNodeArray removeObjectsInRange:range];
    [self.filePathView refreshView];

    CCSandboxEntity *entity = self.filePathView.pathNodeArray.lastObject;
    [self obtainPathItems:entity.filePath];
}

- (void)obtainPathItems:(NSString *)path
{
    NSMutableArray *array = [NSMutableArray array];

    NSFileManager *fileManger = [NSFileManager defaultManager];

    NSArray *dirArray = [fileManger contentsOfDirectoryAtPath:path error:nil];

    [self.fileArray removeAllObjects];
    for (NSString *key in dirArray) {
        if (![key hasPrefix:@"."]) {
            NSString *subPath = [path stringByAppendingPathComponent:key];
            BOOL isDir = NO;
            [fileManger fileExistsAtPath:subPath isDirectory:&isDir];
            NSDictionary *fileAttributes = [fileManger attributesOfItemAtPath:path error:nil];

            CCSandboxEntity *entity = [[CCSandboxEntity alloc] init];
            entity.fileName = key;
            entity.filePath = subPath;
            entity.fileSize = [[fileAttributes objectForKey:NSFileSize] integerValue];
            [entity setType:isDir ? nil : subPath.pathExtension];
            [entity setDate:[fileAttributes objectForKey:NSFileCreationDate]];
            [array addObject:entity];
        }
    }
    [array sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"fileType" ascending:YES] ]];
    self.dataArr = array;
    for (CCSandboxEntity *entity in array) {
        if (entity.fileType != CCFileTypeDirectory)
            [self.fileArray addObject:[CCSandboxPreviewItem previewItemWithPaht:entity.filePath title:entity.fileName]];
    }

    [self.sandboxViewTableView reloadData];
}

#pragma mark - UITableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArr.count;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 70;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CCSandboxTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CCSandboxTableViewCellIdentifer"];
    [cell cc_cellWillDisplayWithModel:_dataArr[ indexPath.row ]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    CCSandboxEntity *entity = self.dataArr[ indexPath.row ];
    if (entity.fileType == CCFileTypeDirectory) {
        [self.filePathView.pathNodeArray addObject:entity];
        [self.filePathView refreshView];
        [self obtainPathItems:entity.filePath];
    } else { //} if (entity.fileType == ){
        [self pushNewViewController:self.fileViewerViewController];
        id obj = [self.fileArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.previewItemTitle == %@", entity.fileName]].lastObject;
        NSInteger index = [self.fileArray indexOfObject:obj];
        self.fileViewerViewController.currentPreviewItemIndex = index;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}


#pragma mark -
#pragma mark :. QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return _fileArray.count;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    CCSandboxPreviewItem *item = [self.fileArray objectAtIndex:index];
    controller.title = item.previewItemTitle;
    return item;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
