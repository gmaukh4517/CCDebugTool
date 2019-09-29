//
//  BundleDirectoryViewTableViewCell.h
//  CCDebugTool
//
//  Created by CC on 2019/9/12.
//  Copyright © 2019 CC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BundleDirectoryViewTableViewCell : UITableViewCell

- (void)cc_cellWillDisplayWithModel:(NSDictionary *)item;

@end

NS_ASSUME_NONNULL_END
