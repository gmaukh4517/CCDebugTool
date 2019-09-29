//
//  LOGCollectionViewCell.h
//  CCDebugTool
//
//  Created by CC on 2019/9/27.
//  Copyright © 2019 CC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LOGCollectionViewCell : UICollectionViewCell

- (void)cc_cellWillDisplayWithModel:(id)cModel indexPath:(NSIndexPath *)cIndexPath;

@end

NS_ASSUME_NONNULL_END
