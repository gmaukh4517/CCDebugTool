//
//  CCBundleDirectoryViewController.m
//  CCDebugTool
//
//  Created by CC on 2019/9/12.
//  Copyright © 2019 CC. All rights reserved.
//

#import "CCBundleDirectoryViewController.h"
#import "BundleDirectoryViewTableViewCell.h"
#import "CCDebugContentViewController.h"
#import "CCSandboxPreviewItem.h"
#import <QuickLook/QuickLook.h>

@interface CCBundleDirectoryViewController () <UITableViewDataSource, UITableViewDelegate, QLPreviewControllerDataSource>

@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, weak) UITableView *bundleTableView;
@property (nonatomic, strong) NSMutableArray *dataArray;

@property (nonatomic) long long currentSize;

@property (nonatomic, strong) QLPreviewController *fileViewerViewController;
@property (nonatomic, strong) NSMutableArray *browseFilesArray;

@end

@implementation CCBundleDirectoryViewController

- (instancetype)initWithPath:(NSString *)path
{
    if (self = [super init]) {
        self.filePath = path;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = self.filePath.lastPathComponent;
    [self initControl];
    [self initLoadData];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.bundleTableView.frame = self.view.bounds;
}

- (void)initControl
{
    UITableView *bundleTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    bundleTableView.backgroundColor = [UIColor clearColor];
    bundleTableView.delegate = self;
    bundleTableView.dataSource = self;
    bundleTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    bundleTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_bundleTableView = bundleTableView];

    if (@available(iOS 11.0, *))
        bundleTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.backgroundColor = [UIColor clearColor];
    [bundleTableView setTableFooterView:v];
}

- (void)initLoadData
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *filesArray = [NSMutableArray array];
        NSMutableArray *browseFilesArray = [NSMutableArray array];

        NSFileManager *fileManager = NSFileManager.defaultManager;
        NSDictionary<NSString *, id> *attributes = [fileManager attributesOfItemAtPath:weakSelf.filePath error:NULL];
        uint64_t totalSize = [attributes fileSize];

        for (NSString *fileName in [fileManager enumeratorAtPath:weakSelf.filePath]) {
            NSString *fullPath = [weakSelf.filePath stringByAppendingPathComponent:fileName];
            attributes = [fileManager attributesOfItemAtPath:fullPath error:NULL];
            totalSize += [attributes fileSize];

            NSMutableDictionary *fileItem = [NSMutableDictionary dictionary];
            [fileItem setObject:fullPath forKey:@"filePath"];
            [fileItem setObject:[UIImage imageWithContentsOfFile:fullPath] ?: [UIImage new] forKey:@"image"];
            [fileItem setObject:fullPath.lastPathComponent forKey:@"fileName"];
            [fileItem setObject:fullPath.lastPathComponent.pathExtension forKey:@"fileExtension"];
            BOOL isDirectory = [attributes.fileType isEqual:NSFileTypeDirectory];
            [fileItem setObject:@(isDirectory) forKey:@"isDirectory"];
            NSString *subtitle = nil;
            if (isDirectory) {
                NSUInteger count = [NSFileManager.defaultManager contentsOfDirectoryAtPath:fullPath error:NULL].count;
                subtitle = [NSString stringWithFormat:@"%lu item%@", (unsigned long)count, (count == 1 ? @"" : @"s")];
            } else {
                NSString *sizeString = [NSByteCountFormatter stringFromByteCount:attributes.fileSize countStyle:NSByteCountFormatterCountStyleFile];
                subtitle = [NSString stringWithFormat:@"%@ - %@", sizeString, attributes.fileModificationDate ?: @"Never modified"];

                [browseFilesArray addObject:[CCSandboxPreviewItem previewItemWithPaht:fullPath title:fullPath.lastPathComponent]];
            }
            [fileItem setObject:subtitle forKey:@"subtitle"];

            [filesArray addObject:fileItem];
            // Bail if the interested view controller has gone away.
            if (!weakSelf) {
                return;
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.currentSize = totalSize;
            strongSelf.dataArray = filesArray;
            strongSelf.browseFilesArray = browseFilesArray;
            [strongSelf.bundleTableView reloadData];
        });
    });

    _fileViewerViewController = [[QLPreviewController alloc] init];
    _fileViewerViewController.dataSource = self;
}

#pragma mark -
#pragma mark :. UITableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sizeString = nil;
    if (!self.currentSize) {
        sizeString = @"Computing size…";
    } else {
        sizeString = [NSByteCountFormatter stringFromByteCount:self.currentSize countStyle:NSByteCountFormatterCountStyleFile];
    }

    return [NSString stringWithFormat:@"%d files (%@)", 1, sizeString];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
        headerView.textLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifer = @"BundleDirectoryViewTableViewCellIdentifier";
    BundleDirectoryViewTableViewCell *cell = (BundleDirectoryViewTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell) {
        cell = [[BundleDirectoryViewTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifer];
    }

    return cell;
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

    [((BundleDirectoryViewTableViewCell *)cell) cc_cellWillDisplayWithModel:[self.dataArray objectAtIndex:indexPath.row]];

    NSInteger totalRows = [tableView numberOfRowsInSection:indexPath.section];
    if ((totalRows - indexPath.row) % 2 == 0) {
        cell.backgroundColor = [UIColor colorWithHue:2.0 / 3.0 saturation:0.02 brightness:0.95 alpha:1];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *fileItem = [self.dataArray objectAtIndex:indexPath.row];
    NSString *filePath = [fileItem objectForKey:@"filePath"];

    BOOL isDirectory = NO;
    BOOL stillExists = [NSFileManager.defaultManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (!stillExists) {
        //        [FLEXAlert showAlert:@"File Not Found" message:@"The file at the specified path no longer exists." from:self];
        //        [self reloadDisplayedPaths];
        return;
    }

    UIViewController *drillInViewController = nil;
    if (isDirectory) {
        drillInViewController = [[[self class] alloc] initWithPath:filePath];
    } else {
        if ([[fileItem objectForKey:@"fileExtension"] isEqualToString:@"png"] || [[fileItem objectForKey:@"fileExtension"] isEqualToString:@"jpg"] || [[fileItem objectForKey:@"fileExtension"] isEqualToString:@"jpge"]) {
            CCDebugContentViewController *viewController = [CCDebugContentViewController new];
            viewController.title = [fileItem objectForKey:@"fileName"];
            viewController.image = [fileItem objectForKey:@"image"];
            drillInViewController = viewController;
        } else if ([[fileItem objectForKey:@"fileExtension"] isEqualToString:@"txt"]) {
            CCDebugContentViewController *viewController = [CCDebugContentViewController new];
            viewController.title = [fileItem objectForKey:@"fileName"];
            viewController.contentURL = [fileItem objectForKey:@"filePath"];
            [self pushCCNewViewController:viewController];
        } else {
            drillInViewController = self.fileViewerViewController;
            id obj = [self.browseFilesArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.previewItemTitle == %@", [fileItem objectForKey:@"fileName"]]].lastObject;
            NSInteger index = [self.browseFilesArray indexOfObject:obj];
            self.fileViewerViewController.currentPreviewItemIndex = index;
        }
    }
    [self pushCCNewViewController:drillInViewController];
}

#pragma mark -
#pragma mark :. QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return self.browseFilesArray.count;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    CCSandboxPreviewItem *item = [self.browseFilesArray objectAtIndex:index];
    controller.title = item.previewItemTitle;
    return item;
}


/*
 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
