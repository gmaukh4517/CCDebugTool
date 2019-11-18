//
//  CCServiceManagerViewController.m
//  CCDebugTool
//
//  Created by CC on 2019/9/9.
//  Copyright © 2019 CC. All rights reserved.
//

#import "CCServiceManagerViewController.h"
#import "CCAddressConfigViewController.h"
#import "CCDebugTool.h"

@interface CCServiceManagerViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableDictionary *serviceAddressConifg;

@property (nonatomic, weak) UISwitch *switchView;

@property (nonatomic, strong) UITableView *serviceAddressTableView;
@property (nonatomic, strong) NSArray *dataArr;

@end

@implementation CCServiceManagerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    self.serviceAddressConifg = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"serviceAddressConifg"]];
    [self initNavigation];
    [self initControl];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initLoadData];
}

- (void)initNavigation
{
    self.title = @"请求服务地址";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"启用" style:UIBarButtonItemStyleDone target:self action:@selector(rightBarButtonItemClick:)];
}

- (void)rightBarButtonItemClick:(UIBarButtonItem *)sender
{
    if ([[self.serviceAddressConifg objectForKey:@"conifg"] boolValue]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"启用配置地址服务需要重启应用" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *_Nonnull action) {
            [[NSUserDefaults standardUserDefaults] setObject:self.serviceAddressConifg forKey:@"serviceAddressConifg"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            exit(0);
        }]];
        [self presentViewController:alert animated:true completion:nil];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"请开启网络请求配置,再启用配置地址服务" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *_Nonnull action) {
            self.switchView.on = YES;
            [self changeConifg:YES];
        }]];
        [self presentViewController:alert animated:true completion:nil];
    }
}

- (void)initControl
{
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
    tableHeaderView.backgroundColor = [UIColor whiteColor];

    UILabel *serviewTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 120, 20)];
    serviewTitleLabel.textColor = [CCDebugTool manager].mainColor;
    serviewTitleLabel.text = @"网络请求配置";
    [tableHeaderView addSubview:serviewTitleLabel];

    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 50, 10, 30, 21)];
    switchView.onTintColor = [CCDebugTool manager].mainColor;
    switchView.tintColor = [UIColor colorWithRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:1];
    [switchView addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
    switchView.transform = CGAffineTransformMakeScale(0.65, 0.65);
    switchView.on = [[self.serviceAddressConifg objectForKey:@"conifg"] boolValue];
    [tableHeaderView addSubview:_switchView = switchView];
    self.serviceAddressTableView.tableHeaderView = tableHeaderView;
}

- (void)switchAction:(UISwitch *)sender
{
    [self changeConifg:sender.on];
}

- (void)changeConifg:(BOOL)conifg
{
    [self.serviceAddressConifg setObject:@(conifg) forKey:@"conifg"];
    NSMutableArray *dataArray = [NSMutableArray array];
    for (NSDictionary *item in [self.serviceAddressConifg objectForKey:@"address"]) {
        NSMutableDictionary *newItem = [NSMutableDictionary dictionaryWithDictionary:item];
        [newItem setObject:@(NO) forKey:@"selected"];
        [dataArray addObject:newItem];
    }
    [self.serviceAddressConifg setObject:dataArray forKey:@"address"];

    self.dataArr = @[];
    if ([[self.serviceAddressConifg objectForKey:@"conifg"] boolValue])
        self.dataArr = dataArray;

    [[NSUserDefaults standardUserDefaults] setObject:self.serviceAddressConifg forKey:@"serviceAddressConifg"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.serviceAddressTableView reloadData];
}

- (void)initLoadData
{
    self.serviceAddressConifg = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"serviceAddressConifg"]];
    self.dataArr = @[];
    if ([[self.serviceAddressConifg objectForKey:@"conifg"] boolValue])
        self.dataArr = [self.serviceAddressConifg objectForKey:@"address"];
    [self.serviceAddressTableView reloadData];
}

#pragma mark -
#pragma mark :. event handler

- (void)addConfigButtonClick:(UIButton *)sender
{
    [self pushCCNewViewController:[CCAddressConfigViewController new]];
}

#pragma mark -
#pragma mark :. UITableViewDelegate & UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0;
    if ([[self.serviceAddressConifg objectForKey:@"conifg"] boolValue])
        height = 40;

    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView;
    if ([[self.serviceAddressConifg objectForKey:@"conifg"] boolValue]) {
        headerView = [UIView new];

        UILabel *tipsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 100, 10)];
        tipsLabel.font = [UIFont systemFontOfSize:12];
        tipsLabel.textColor = [UIColor colorWithRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:1];
        tipsLabel.text = @"地址列表";
        [headerView addSubview:tipsLabel];

        UIButton *addConfigButton = [[UIButton alloc] initWithFrame:CGRectMake(tableView.bounds.size.width - 50, 10, 50, 30)];
        addConfigButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [addConfigButton setTitle:@"新增" forState:UIControlStateNormal];
        [addConfigButton setTitleColor:[CCDebugTool manager].mainColor forState:UIControlStateNormal];
        [addConfigButton addTarget:self action:@selector(addConfigButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:addConfigButton];
    }
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *dataArray = [NSMutableArray array];
    for (NSDictionary *item in self.dataArr) {
        NSMutableDictionary *newItem = [NSMutableDictionary dictionaryWithDictionary:item];
        [newItem setObject:@(NO) forKey:@"selected"];
        [dataArray addObject:newItem];
    }

    NSMutableDictionary *selececdItem = [dataArray objectAtIndex:indexPath.row];
    [selececdItem setObject:@(YES) forKey:@"selected"];
    [dataArray replaceObjectAtIndex:indexPath.row withObject:selececdItem];
    self.dataArr = dataArray;
    [self.serviceAddressConifg setObject:self.dataArr forKey:@"address"];
    [tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifer = @"serviceAddressIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifer];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = [CCDebugTool manager].mainColor;
    }

    cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:15];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self.dataArr objectAtIndex:indexPath.row];
    NSString *serviceName = [item objectForKey:@"title"];
    NSString *serviceAddress = [[item objectForKey:@"parameter"] objectForKey:@"ServiceAddress"];
    if (serviceAddress)
        serviceName = [NSString stringWithFormat:@"%@ (%@)", serviceName, serviceAddress];
    cell.textLabel.text = serviceName;

    BOOL selected = [[item objectForKey:@"selected"] boolValue];
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (selected)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;

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

- (nullable UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
API_AVAILABLE(ios(11.0))
{
    __weak typeof(self) weakSelf = self;
    UIContextualAction *topAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                            title:@"编辑"
                                                                          handler:^(UIContextualAction *_Nonnull action, __kindof UIView *_Nonnull sourceView, void (^_Nonnull completionHandler)(BOOL)) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        CCAddressConfigViewController *viewController = [CCAddressConfigViewController new];
        viewController.dataItem = [strongSelf.dataArr objectAtIndex:indexPath.row];
        [strongSelf pushCCNewViewController:viewController];

        [tableView setEditing:NO animated:YES];
        completionHandler(true);
    }];

    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                               title:@"删除"
                                                                             handler:^(UIContextualAction *_Nonnull action, __kindof UIView *_Nonnull sourceView, void (^_Nonnull completionHandler)(BOOL)) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSMutableArray *dataArray = [NSMutableArray arrayWithArray:strongSelf.dataArr];
        [dataArray removeObjectAtIndex:indexPath.row];
        [strongSelf.serviceAddressConifg setObject:dataArray forKey:@"address"];

        [[NSUserDefaults standardUserDefaults] setObject:strongSelf.serviceAddressConifg forKey:@"serviceAddressConifg"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [strongSelf initLoadData];

        [tableView setEditing:NO animated:YES];
        completionHandler(true);
    }];

    UISwipeActionsConfiguration *actions = [UISwipeActionsConfiguration configurationWithActions:@[ deleteAction, topAction ]];
    // 禁止侧滑无线拉伸
    actions.performsFirstActionWithFullSwipe = NO;
    return actions;
}

- (UITableView *)serviceAddressTableView
{
    if (!_serviceAddressTableView) {
        _serviceAddressTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _serviceAddressTableView.backgroundColor = [UIColor colorWithRed:243.0 / 255.0 green:245.0 / 255.0 blue:247.0 / 255.0 alpha:1];
        _serviceAddressTableView.delegate = self;
        _serviceAddressTableView.dataSource = self;
        _serviceAddressTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _serviceAddressTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:_serviceAddressTableView];

        if (@available(iOS 11.0, *))
            _serviceAddressTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor clearColor];
        [_serviceAddressTableView setTableFooterView:v];
    }
    return _serviceAddressTableView;
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
