
//
//  CCFilePathTreeView.m
//  CCDebugTool
//
//  Created by CC on 2017/11/3.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCFilePathTreeView.h"
#import "CCSandboxCollectionViewCell.h"

@interface CCFilePathTreeView() <UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *filePathCollectionView;

@end

@implementation CCFilePathTreeView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.filePathCollectionView];
    }
    return self;
}

- (float)getSinglelineStringWidth:(NSString*)aString
{
    if (aString == nil) return 0;
    CGSize measureSize = [aString boundingRectWithSize:CGSizeMake(MAXFLOAT, 20)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}
                                               context:nil].size;
    return ceil(measureSize.width);
}

- (void)refreshView
{
    [self.filePathCollectionView reloadData];
    
    dispatch_after(dispatch_walltime(DISPATCH_TIME_NOW, (int64_t)(0.001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGFloat x = self->_filePathCollectionView.contentSize.width + self->_filePathCollectionView.contentInset.right - self->_filePathCollectionView.bounds.size.width;
        [self->_filePathCollectionView setContentOffset:CGPointMake(x < 0 ? 0 : x, 0.0f) animated:YES];
    });
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    self.filePathCollectionView.frame = self.bounds;
}

#pragma mark -
#pragma mark :. UICollectionViewDelegate && UICollectionViewDataSourse

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.pathNodeArray.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CCSandboxEntity *entity = self.pathNodeArray[indexPath.row];
    float itemWidth = [self getSinglelineStringWidth:entity.fileName];
    return CGSizeMake(itemWidth + 20, self.bounds.size.height);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CCSandboxCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CCSandboxCollectionViewCellIdentifer" forIndexPath:indexPath];
    [cell cc_cellWillDisplayWithModel:self.pathNodeArray[indexPath.row] isSelected:indexPath.row == self.pathNodeArray.count - 1];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(filePathTreeViewDidSelectItem:)]) {
        [self.delegate filePathTreeViewDidSelectItem:self.pathNodeArray[indexPath.row]];
    }
}

#pragma mark -
#pragma mark :. getter/setter
- (UICollectionView *)filePathCollectionView
{
    if (!_filePathCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        collectionView.dataSource = self;
        collectionView.delegate = self;
        collectionView.showsHorizontalScrollIndicator = NO;
        
        [collectionView registerClass:[CCSandboxCollectionViewCell class] forCellWithReuseIdentifier:@"CCSandboxCollectionViewCellIdentifer"];
        _filePathCollectionView = collectionView;
    }
    return _filePathCollectionView;
}

- (NSMutableArray *)pathNodeArray {
    if (!_pathNodeArray) {
        _pathNodeArray = [NSMutableArray array];
    }
    return _pathNodeArray;
}


@end
