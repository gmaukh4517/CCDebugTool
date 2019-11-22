//
//  CCStatisticsTableViewCell.h
//  CCDebugTool
//
//  Created by CC on 2019/11/19.
//  Copyright © 2019 CC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCStatisticsTableViewCell : UITableViewCell

- (void)cc_cellWillDisplayWithModel:(id)cModel indexPath:(NSIndexPath *)cIndexPath;

@end

NS_ASSUME_NONNULL_END
