//
//  CCDebugKeychainViewController.m
//  CCDebugTool
//
//  Created by CC on 2019/9/12.
//  Copyright © 2019 CC. All rights reserved.
//

#import "CCDebugKeychainViewController.h"
#import "CCDebugAlert.h"
#import "CCDebugKeychain.h"
#import "CCDebugKeychainQuery.h"

@interface CCDebugKeychainViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) UITableView *keychainTableView;
@property (nonatomic, strong) NSArray *dataArr;

@end

@implementation CCDebugKeychainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithRed:243.0 / 255.0 green:245.0 / 255.0 blue:247.0 / 255.0 alpha:1];
    [self initNavigation];
    [self initControl];
    [self initLoadData];
}

- (void)initNavigation
{
    self.title = @"Key chain";
    self.navigationItem.rightBarButtonItems = @[
                                                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                                              target:self
                                                                                              action:@selector(trashPressed)],
                                                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                              target:self
                                                                                              action:@selector(addPressed)],
                                                ];
}

- (void)trashPressed
{
    [CCDebugAlert makeSheet:^(CCDebugAlert *make) {
        make.title(@"Clear Keychain");
        make.message(@"这将删除此应用的所有钥匙串项目。\n");
        make.message(@"此操作无法撤消。 你确定吗？");
        make.button(@"是的，清除钥匙串").destructiveStyle().handler(^(NSArray *strings) {
            for (id account in self.dataArr) {
                CCDebugKeychainQuery *query = [CCDebugKeychainQuery new];
                query.service = account[ kCCDebugKeychainWhereKey ];
                query.account = account[ kCCDebugKeychainAccountKey ];

                // Delete item or display error
                NSError *error = nil;
                if (![query deleteItem:&error]) {
                    [CCDebugAlert makeAlert:^(CCDebugAlert *make) {
                        make.title(@"Error Deleting Item");
                        make.message(error.localizedDescription);
                    }
                                   showFrom:self];
                }
            }
            [self initLoadData];
        });
        make.button(@"Cancel").cancelStyle();
    }
                   showFrom:self];
}

- (void)addPressed
{
    [CCDebugAlert makeAlert:^(CCDebugAlert *make) {
        make.title(@"添加钥匙串");
        make.textField(@"服务名称，即Instagram");
        make.textField(@"帐户，即username@example.com");
        make.textField(@"密码");
        make.button(@"取消").cancelStyle();
        make.button(@"保存").handler(^(NSArray<NSString *> *strings) {
            // Display errors
            NSError *error = nil;
            if (![CCDebugKeychain setPassword:strings[ 2 ] forService:strings[ 0 ] account:strings[ 1 ] error:&error]) {
                [CCDebugAlert showAlert:@"Error" message:error.localizedDescription from:self];
            }

            [self initLoadData];
        });
    }
                   showFrom:self];
}

- (void)initControl
{
    UITableView *keychainTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    keychainTableView.backgroundColor = [UIColor clearColor];
    keychainTableView.delegate = self;
    keychainTableView.dataSource = self;
    keychainTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    keychainTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_keychainTableView = keychainTableView];

    if (@available(iOS 11.0, *))
        keychainTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.backgroundColor = [UIColor clearColor];
    [keychainTableView setTableFooterView:v];
}

- (void)initLoadData
{
    self.dataArr = [CCDebugKeychain allAccounts];
    [self.keychainTableView reloadData];
}

#pragma mark -
#pragma mark :. UITableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifer = @"BundleDirectoryViewTableViewCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifer];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
        cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self.dataArr objectAtIndex:indexPath.row];
    cell.textLabel.text = item[ kCCDebugKeychainAccountKey ];

    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }

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

    NSDictionary *item = self.dataArr[ indexPath.row ];

    CCDebugKeychainQuery *query = [CCDebugKeychainQuery new];
    query.service = item[ kCCDebugKeychainWhereKey ];
    query.account = item[ kCCDebugKeychainAccountKey ];
    [query fetch:nil];

    [CCDebugAlert makeAlert:^(CCDebugAlert *make) {
        make.title(query.service);
        make.message(@"Service: ").message(query.service);
        make.message(@"\nAccount: ").message(query.account);
        make.message(@"\nPassword: ").message(query.password);

        make.button(@"Copy Service").handler(^(NSArray<NSString *> *strings) {
            UIPasteboard.generalPasteboard.string = query.service;
        });
        make.button(@"Copy Account").handler(^(NSArray<NSString *> *strings) {
            UIPasteboard.generalPasteboard.string = query.account;
        });
        make.button(@"Copy Password").handler(^(NSArray<NSString *> *strings) {
            UIPasteboard.generalPasteboard.string = query.password;
        });
        make.button(@"Dismiss").cancelStyle();
    }
                   showFrom:self];
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
