//
//  AddressConfigTableViewCell.h
//  CCDebugTool
//
//  Created by CC on 2019/9/9.
//  Copyright © 2019 CC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AddressConfigTableViewCell : UITableViewCell

@property (nonatomic, copy) void (^textFieldChange)(UITextField *textField);

- (void)cc_cellWillDisplayWithModel:(id)cModel indexPath:(NSIndexPath *)cIndexPath;

@end

NS_ASSUME_NONNULL_END
