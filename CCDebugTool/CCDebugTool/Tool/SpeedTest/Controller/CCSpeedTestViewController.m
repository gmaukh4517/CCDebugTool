//
//  SpeedTestViewController.m
//  CCDebugTool
//
//  Created by CC on 2017/11/7.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCSpeedTestViewController.h"
#import "CCSpeedView.h"
#import "CCSpeedTestManager.h"

@interface CCSpeedTestViewController ()

@property (nonatomic, strong) CCSpeedView *speedView;

@property (nonatomic, strong) CCSpeedTestManager *speedTest;

@property (nonatomic, strong) UILabel *delayLabel;
@property (nonatomic, strong) UILabel *downLoadLabel;
@property (nonatomic, strong) UILabel *upLoadLabel;

@property (nonatomic, assign) NSInteger currentType;

@end

@implementation CCSpeedTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithRed:0.098 green:0.5059 blue:0.8039 alpha:1.0];
    [self initSpeedTest];
    [self initControl];
}

- (void)initControl
{
    NSInteger spacing = 150;
    CGFloat width = self.view.bounds.size.width - spacing;
    CCSpeedView *speedView = [[CCSpeedView alloc] initWithFrame:CGRectMake(spacing / 2, 40, width , width)];
    [self.view addSubview:_speedView = speedView];
    [self initSpeedContentView];
//    [_speedTest startDownLoad];
    [CCSpeedTestManager getWifiName];
}

-(void)initSpeedTest
{
    _speedTest = [[CCSpeedTestManager alloc] init];
    __weak typeof(self) wSelf = self;
    _speedTest.speedBlock = ^(NSInteger speed){
        NSString *unit;
        wSelf.speedView.speed = [CCSpeedTestManager formattedFileSize:speed unit:&unit];
        wSelf.speedView.unit = [NSString stringWithFormat:@"%@/s",unit?:@"KB"];
        
        float progress = 0;
        if ([unit isEqualToString:@"KB"]) {
            progress = speed / 1024;
        }else if ([unit isEqualToString:@"MB"]){
            progress = speed / 1024;
        }else if ([unit isEqualToString:@"GB"]){
            progress =  speed / 1024;
        }
        
        wSelf.speedView.speedProgress = progress;
    };
    
    _speedTest.finishBlock = ^(NSInteger finishSpeed){
        wSelf.speedView.speed = @"0";
        wSelf.speedView.unit = @"KB/s";
        wSelf.speedView.speedProgress = 0;
        
        NSString *unit;
        NSString *speedStr = [CCSpeedTestManager formatBandWidth:finishSpeed unit:&unit];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@/s",speedStr,unit]];
        [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:20.0] range:NSMakeRange(0, speedStr.length)];
        if (wSelf.currentType == 0){
            wSelf.downLoadLabel.attributedText = attributedString;
        }else{
            wSelf.upLoadLabel.attributedText = attributedString;
        }
        
        if (wSelf.currentType == 0) {
            wSelf.currentType = 1;
            [wSelf.speedTest startUpLoad];
        }
    };
}

-(void)initSpeedContentView
{
    CGFloat width = (self.view.bounds.size.width - 3) / 3;
    
    UIView *speedContentView = [[UIView alloc] initWithFrame:CGRectMake(0, _speedView.frame.origin.y + _speedView.frame.size.height + 20, self.view.bounds.size.width, 50)];
    [self.view addSubview:speedContentView];
    
    NSArray *arr = @[@"网络延迟",@"下载速度",@"上传速度"];
    NSInteger x = 0;
    for (NSInteger i = 0; i < arr.count; i++) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width, 20)];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont systemFontOfSize:12];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.text = [arr objectAtIndex:i];
        [speedContentView addSubview:titleLabel];
        
        UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(x,titleLabel.frame.origin.y + titleLabel.frame.size.height, width, 30)];
        contentLabel.textColor = [UIColor whiteColor];
        contentLabel.font = [UIFont systemFontOfSize:12];
        contentLabel.textAlignment = NSTextAlignmentCenter;
        contentLabel.text = @"•••";
        [speedContentView addSubview:contentLabel];
        if (i == 0)
            _delayLabel = contentLabel;
        else if (i == 1)
            _downLoadLabel = contentLabel;
        else if (i == 2)
            _upLoadLabel = contentLabel;
        
        x+=width;
        if (i < arr.count - 1) {
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(x, 5, 0.5, 40)];
            line.backgroundColor = [UIColor lightGrayColor];
            [speedContentView addSubview:line];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
