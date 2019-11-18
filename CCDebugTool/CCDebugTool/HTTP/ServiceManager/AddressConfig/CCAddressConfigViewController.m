//
//  CCAddressConfigViewController.m
//  CCDebugTool
//
//  Created by CC on 2019/9/9.
//  Copyright © 2019 CC. All rights reserved.
//

#import "CCAddressConfigViewController.h"
#import "CCAddressConfigTableViewCell.h"
#import "CCDebugTool.h"

@interface CCAddressConfigViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *addressConfigTableView;
@property (nonatomic, strong) NSMutableArray *dataArray;

@property (nonatomic, weak) UITextField *configTextField;

@end

@implementation CCAddressConfigViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self initNavigation];
    [self initControl];

    self.dataArray = [NSMutableArray array];


    if (self.dataItem) {
        NSDictionary *item = [self.dataItem objectForKey:@"parameter"];
        for (id key in item.allKeys)
            [self.dataArray addObject:@{ @"key" : key,
                                         @"value" : [item objectForKey:key] }];
    } else {
        [self.dataArray addObject:@{ @"key" : @"",
                                     @"value" : @"" }];
    }
}

- (void)initNavigation
{
    self.title = @"新增服务地址配置";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(rightBarButtonItemClick:)];
}

- (void)rightBarButtonItemClick:(UIBarButtonItem *)sender
{
    NSMutableDictionary *serviceAddressConifg = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"serviceAddressConifg"]];
    NSMutableArray *address = [NSMutableArray arrayWithArray:[serviceAddressConifg objectForKey:@"address"]];

    NSMutableDictionary *addressConfigDic = [NSMutableDictionary dictionary];
    [addressConfigDic setObject:self.configTextField.text.length ? self.configTextField.text : [NSString stringWithFormat:@"配置%d", (int)address.count + 1] forKey:@"title"];
    [addressConfigDic setObject:@NO forKey:@"selected"];

    NSMutableDictionary *items = [NSMutableDictionary dictionary];
    for (NSDictionary *item in self.dataArray)
        [items setObject:[item objectForKey:@"value"] forKey:[item objectForKey:@"key"]];
    [addressConfigDic setObject:items forKey:@"parameter"];

    if (self.dataItem)
        [address replaceObjectAtIndex:[address indexOfObject:self.dataItem] withObject:addressConfigDic];
    else
        [address addObject:addressConfigDic];

    [serviceAddressConifg setObject:address forKey:@"address"];
    [[NSUserDefaults standardUserDefaults] setObject:serviceAddressConifg forKey:@"serviceAddressConifg"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)initControl
{
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
    tableHeaderView.backgroundColor = [UIColor whiteColor];

    UILabel *keyTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
    keyTitleLabel.textAlignment = NSTextAlignmentCenter;
    keyTitleLabel.font = [UIFont systemFontOfSize:15];
    keyTitleLabel.text = @"配置标题";
    keyTitleLabel.textColor = [CCDebugTool manager].mainColor;
    [tableHeaderView addSubview:keyTitleLabel];

    UITextField *configTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, tableHeaderView.frame.size.width - 20, 50)];
    configTextField.placeholder = @"显示配置表示";
    configTextField.text = [self.dataItem objectForKey:@"title"];
    configTextField.leftView = keyTitleLabel;
    configTextField.leftViewMode = UITextFieldViewModeAlways;
    [tableHeaderView addSubview:_configTextField = configTextField];
    self.addressConfigTableView.tableHeaderView = tableHeaderView;

    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 60)];

    UIButton *addConfigButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 20, tableFooterView.frame.size.width - 20, 40)];
    addConfigButton.backgroundColor = [CCDebugTool manager].mainColor;
    [addConfigButton setTitle:@"新增字段" forState:UIControlStateNormal];
    [addConfigButton addTarget:self action:@selector(addConfigButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    addConfigButton.layer.cornerRadius = 5;
    [tableFooterView addSubview:addConfigButton];

    self.addressConfigTableView.tableFooterView = tableFooterView;
}


- (void)addConfigButtonClick:(UIButton *)sender
{
    [self.dataArray addObject:@{ @"key" : @"",
                                 @"value" : @"" }];

    [self.addressConfigTableView reloadData];
}

#pragma mark -
#pragma mark :. UITableViewDelegate & UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [UIView new];

    UILabel *tipsLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 100, 10)];
    tipsLabel.font = [UIFont systemFontOfSize:12];
    tipsLabel.textColor = [UIColor colorWithRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:1];
    tipsLabel.text = @"键值";
    [headerView addSubview:tipsLabel];

    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifer = @"serviceAddressIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell) {
        CCAddressConfigTableViewCell *addressCell = [[CCAddressConfigTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifer];
        addressCell.selectionStyle = UITableViewCellSelectionStyleNone;
        __weak typeof(self) weakSelf = self;
        [addressCell setTextFieldChange:^(UITextField *_Nonnull textField) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[strongSelf.dataArray objectAtIndex:indexPath.row]];
            NSString *key = @"value";
            if (textField.tag) {
                key = @"key";
            }
            [item setObject:textField.text ?: @"" forKey:key];
            [strongSelf.dataArray replaceObjectAtIndex:indexPath.row withObject:item];
        }];
        cell = addressCell;
    }

    cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:15];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    CCAddressConfigTableViewCell *addressCell = (CCAddressConfigTableViewCell *)cell;
    [addressCell cc_cellWillDisplayWithModel:[self.dataArray objectAtIndex:indexPath.row] indexPath:indexPath];

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

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    UITableViewRowAction *rowActionSec = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                            title:@"删除"
                                                                          handler:^(UITableViewRowAction *_Nonnull action, NSIndexPath *_Nonnull indexPath) {
                                                                              __strong typeof(weakSelf) strongSelf = weakSelf;
                                                                              [strongSelf.dataArray removeObjectAtIndex:indexPath.row];
                                                                              [strongSelf.addressConfigTableView reloadData];
                                                                          }];

    rowActionSec.backgroundColor = [UIColor redColor];


    return @[ rowActionSec ];
}

- (UITableView *)addressConfigTableView
{
    if (!_addressConfigTableView) {
        _addressConfigTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _addressConfigTableView.backgroundColor = [UIColor colorWithRed:243.0 / 255.0 green:245.0 / 255.0 blue:247.0 / 255.0 alpha:1];
        _addressConfigTableView.delegate = self;
        _addressConfigTableView.dataSource = self;
        _addressConfigTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _addressConfigTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:_addressConfigTableView];

        if (@available(iOS 11.0, *))
            _addressConfigTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor clearColor];
        [_addressConfigTableView setTableFooterView:v];
    }
    return _addressConfigTableView;
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
