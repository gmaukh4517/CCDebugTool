//
//  CCAddressConfigTableViewCell.m
//  CCDebugTool
//
//  Created by CC on 2019/9/9.
//  Copyright © 2019 CC. All rights reserved.
//

#import "CCAddressConfigTableViewCell.h"
#import "CCDebugTool.h"

@interface CCAddressConfigTableViewCell ()

@property (nonatomic, weak) UITextField *keyTextField;
@property (nonatomic, weak) UITextField *valueTextField;

@end

@implementation CCAddressConfigTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectedBackgroundView = [UIView new];
        [self initControl];
    }
    return self;
}

- (void)cc_cellWillDisplayWithModel:(id)cModel indexPath:(NSIndexPath *)cIndexPath
{
    NSDictionary *item = cModel;

    self.keyTextField.text = [item objectForKey:@"key"];
    self.valueTextField.text = [item objectForKey:@"value"];
}

- (void)initControl
{
    UILabel *keyTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
    keyTitleLabel.textAlignment = NSTextAlignmentCenter;
    keyTitleLabel.font = [UIFont systemFontOfSize:15];
    keyTitleLabel.text = @"Key";
    [self.contentView addSubview:keyTitleLabel];

    UITextField *keyTextField = [UITextField new];
    keyTextField.font = [UIFont systemFontOfSize:14];
    keyTextField.tag = 0;
    keyTextField.placeholder = @"对应字段Key";
    keyTextField.leftView = keyTitleLabel;
    keyTextField.leftViewMode = UITextFieldViewModeAlways;
    [keyTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.contentView addSubview:_keyTextField = keyTextField];


    UILabel *valueTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
    valueTitleLabel.textAlignment = NSTextAlignmentCenter;
    valueTitleLabel.font = [UIFont systemFontOfSize:15];
    valueTitleLabel.text = @"Value";
    [self.contentView addSubview:valueTitleLabel];

    UITextField *valueTextField = [UITextField new];
    valueTextField.font = [UIFont systemFontOfSize:14];
    valueTextField.tag = 1;
    valueTextField.placeholder = @"对应字段Value";
    valueTextField.leftView = valueTitleLabel;
    valueTextField.leftViewMode = UITextFieldViewModeAlways;
    [valueTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.contentView addSubview:_valueTextField = valueTextField];
}

- (void)textFieldDidChange:(UITextField *)sender
{
    !self.textFieldChange ?: self.textFieldChange(sender);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGSize size = self.contentView.bounds.size;
    CGFloat width = (size.width - 15) / 2;

    CGRect frame = self.keyTextField.frame;
    frame.origin.x = 5;
    frame.size.height = size.height;
    frame.size.width = width;
    self.keyTextField.frame = frame;

    frame = self.valueTextField.frame;
    frame.origin.x = self.keyTextField.frame.origin.x + self.keyTextField.frame.size.width + 5;
    frame.size.height = size.height;
    frame.size.width = width;
    self.valueTextField.frame = frame;
}

@end
