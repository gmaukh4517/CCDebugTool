//
//  DatabaseViewController.m
//  CCDebugTool
//
//  Created by CC on 2017/12/6.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "DatabaseViewController.h"
#import "DatabaseViewModel.h"
#import "LeftDatabaseView.h"
#import "CCDebugTool.h"

static NSString *const kUICollectionViewCellIdentify = @"kUICollectionViewCellIdentify";

@interface DatabaseViewController () <LeftDatabaseViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *contentScrollView;

@property (nonatomic, strong) UICollectionView *headerCollectionView;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) LeftDatabaseView *leftDatabaseView;

@property (nonatomic, copy) NSArray *headerDataArr;
@property (nonatomic, copy) NSArray *dataArr;

@property (nonatomic, strong) DatabaseViewModel *viewModel;

@property (nonatomic, strong) UIView *verticalLine;

@property (nonatomic, copy) NSString *currentPath;
@property (nonatomic, copy) NSString *currentTable;

@end

@implementation DatabaseViewController

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
    self.navigationItem.title = @"数据库";
}

- (void)initControl
{
    self.view.backgroundColor = [UIColor whiteColor];
    self.leftDatabaseView = [[LeftDatabaseView alloc] initWithFrame:CGRectMake(0, 0, 100, self.view.bounds.size.height - 64)];
    self.leftDatabaseView.delegate = self;
    [self.view addSubview:self.leftDatabaseView];

    UILabel *dataLabel = [[UILabel alloc] initWithFrame:CGRectMake(_leftDatabaseView.frame.size.width, 0, self.view.bounds.size.width - _leftDatabaseView.frame.size.width, 30)];
    dataLabel.textColor = [UIColor whiteColor];
    dataLabel.backgroundColor = [CCDebugTool manager].mainColor;
    dataLabel.font = [UIFont systemFontOfSize:15];
    dataLabel.text = @"  Data";
    [self.view addSubview:dataLabel];

    CGFloat y = dataLabel.frame.origin.y + dataLabel.frame.size.height;

    self.contentScrollView.frame = CGRectMake(_leftDatabaseView.frame.size.width, y, self.view.bounds.size.width - _leftDatabaseView.frame.size.width, self.view.bounds.size.height - y - 64);
    [self.view addSubview:self.contentScrollView];

    self.headerCollectionView.frame = CGRectMake(0, 0, self.contentScrollView.frame.size.width, 30);
    [self.contentScrollView addSubview:self.headerCollectionView];

    UIView *verticalLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.headerCollectionView.frame.origin.y + self.headerCollectionView.frame.size.height, self.contentScrollView.frame.size.width, 1)];
    verticalLine.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1];
    verticalLine.hidden = YES;
    [self.contentScrollView addSubview:_verticalLine = verticalLine];

    self.collectionView.frame = CGRectMake(0, verticalLine.frame.origin.y + verticalLine.frame.size.height, self.contentScrollView.frame.size.width, self.contentScrollView.frame.size.height - self.verticalLine.frame.origin.y - self.verticalLine.frame.size.height - 20);
    [self.contentScrollView addSubview:self.collectionView];
}

- (void)initLoadData
{
    if (!_viewModel) {
        _viewModel = [[DatabaseViewModel alloc] init];
    }

    [self.leftDatabaseView fillDatabase:[_viewModel obtainAllDatabase]];
}

#pragma mark -
#pragma mark :. LeftDatabaseViewDelegate

- (void)didDatabaseClick:(NSString *)databasePath
{
    if ([databasePath isEqualToString:self.currentPath])
        return;
    self.currentPath = databasePath;

    _verticalLine.hidden = YES;
    [self.leftDatabaseView fillTable:[_viewModel obtainAllTable:databasePath]];

    self.headerDataArr = nil;
    self.dataArr = nil;
    [self.headerCollectionView reloadData];
    [self.collectionView reloadData];
}

- (void)didTableClick:(NSString *)tableName
{
    if ([tableName isEqualToString:self.currentTable])
        return;
    self.currentTable = tableName;

    NSDictionary *dataDic = [_viewModel obtainAllColumnNameData:tableName];
    self.dataArr = [dataDic objectForKey:@"dataArr"];
    self.headerDataArr = [dataDic objectForKey:@"columnArr"];

    CGFloat width = [self totalWidth];
    self.contentScrollView.contentSize = CGSizeMake(width, 0);

    CGRect frame = self.headerCollectionView.frame;
    frame.size.width = width;
    self.headerCollectionView.frame = frame;

    frame = self.collectionView.frame;
    frame.size.width = width;
    self.collectionView.frame = frame;

    width = width < self.contentScrollView.frame.size.width ? self.contentScrollView.frame.size.width : width;

    frame = self.verticalLine.frame;
    frame.size.width = width;
    self.verticalLine.frame = frame;
    _verticalLine.hidden = NO;

    [self.headerCollectionView reloadData];
    dispatch_after(dispatch_walltime(DISPATCH_TIME_NOW, (int64_t)(0.001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });
}

- (CGFloat)totalWidth
{
    CGFloat width = 0;
    for (NSDictionary *item in self.headerDataArr) {
        NSString *columnKey = [item objectForKey:@"name"];

        CGSize contentSize = [columnKey boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 30) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:15] } context:nil].size;

        width += contentSize.width < 100 ? 100 : contentSize.width;
    }
    return width;
}

#pragma mark -
#pragma mark :. UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSInteger section = 1;
    if (collectionView == self.collectionView) {
        section = self.dataArr.count;
    }
    return section;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if (collectionView == self.headerCollectionView) {
        count = self.headerDataArr.count;
    } else if (collectionView == self.collectionView) {
        count = self.headerDataArr.count;
    }
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kUICollectionViewCellIdentify forIndexPath:indexPath];
    NSString *content;
    if (collectionView == self.headerCollectionView) {
        content = [[self.headerDataArr objectAtIndex:indexPath.row] objectForKey:@"name"];
    } else if (collectionView == self.collectionView) {
        NSString *columnKey = [[self.headerDataArr objectAtIndex:indexPath.row] objectForKey:@"name"];
        NSDictionary *dataDic = [[self.dataArr objectAtIndex:indexPath.section] objectForKey:columnKey];
        content = [NSString stringWithFormat:@"%@", [dataDic objectForKey:@"value"]];

        UIColor *color = [UIColor whiteColor];
        if (indexPath.section % 2 == 0) {
            color = [UIColor colorWithRed:0.967 green:0.967 blue:0.967 alpha:0.7];
        }
        cell.backgroundColor = color;
    }

    UILabel *contentLabel = (UILabel *)[cell.contentView viewWithTag:123];
    if (!contentLabel) {
        contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, cell.bounds.size.width - 5, cell.bounds.size.height)];
        contentLabel.font = [UIFont systemFontOfSize:15];
        contentLabel.tag = 123;
        [cell.contentView addSubview:contentLabel];
    }

    contentLabel.text = content;

    return cell;
}

#pragma mark -
#pragma mark :. UICollectionViewDelegate method

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if ([NSStringFromSelector(action) isEqualToString:@"copy:"] || [NSStringFromSelector(action) isEqualToString:@"paste:"])
        return YES;
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    NSLog(@"复制之后，可以插入一个新的cell");
}

#pragma mark -
#pragma mark :. UICollectionViewDelegateFlowLayout method
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = CGSizeZero;
    if (collectionView == self.headerCollectionView) {
        size = [self adjustmentSize:indexPath.row];
    } else if (collectionView == self.collectionView) {
        size = [self adjustmentSize:indexPath.row];
    }
    return size;
}

- (CGSize)adjustmentSize:(NSInteger)section
{
    NSString *content = [[self.headerDataArr objectAtIndex:section] objectForKey:@"name"];

    CGSize contentSize = [content boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 30) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:15] } context:nil].size;

    return CGSizeMake(contentSize.width < 100 ? 100 : contentSize.width, 30);
}

//定义每个UICollectionView 的 margin
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}


#pragma mark -
#pragma mark :. getter/setter

- (UIScrollView *)contentScrollView
{
    if (!_contentScrollView) {
        _contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _contentScrollView.showsHorizontalScrollIndicator = NO;
        _contentScrollView.showsVerticalScrollIndicator = NO;
        _contentScrollView.pagingEnabled = NO;
        _contentScrollView.bounces = NO;
        _contentScrollView.scrollsToTop = NO;
        _contentScrollView.delegate = self;
        _contentScrollView.backgroundColor = [UIColor whiteColor];
    }
    return _contentScrollView;
}

- (UICollectionView *)headerCollectionView
{
    if (!_headerCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;

        _headerCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _headerCollectionView.backgroundColor = [UIColor whiteColor];
        _headerCollectionView.dataSource = self;
        _headerCollectionView.delegate = self;
        _headerCollectionView.showsVerticalScrollIndicator = NO;
        [_headerCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kUICollectionViewCellIdentify];
    }
    return _headerCollectionView;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;

        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.showsVerticalScrollIndicator = NO;
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kUICollectionViewCellIdentify];
    }
    return _collectionView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
