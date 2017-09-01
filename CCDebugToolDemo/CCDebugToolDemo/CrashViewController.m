//
//  CrashViewController.m
//  CCDebugToolDemo
//
//  Created by CC on 2017/9/1.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CrashViewController.h"

typedef struct Test {
    int a;
    int b;
} Test;

@implementation CrashViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *crashExcButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 200, 120, 100)];
    crashExcButton.backgroundColor = [UIColor redColor];
    [crashExcButton setTitle:@"Exception" forState:UIControlStateNormal];
    [crashExcButton addTarget:self action:@selector(crashExcClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:crashExcButton];
    
    UIButton *crashSignalEGVButton = [[UIButton alloc] initWithFrame:CGRectMake(200, 200, 120, 100)];
    crashSignalEGVButton.backgroundColor = [UIColor redColor];
    [crashSignalEGVButton setTitle:@"Signal(EGV)" forState:UIControlStateNormal];
    [crashSignalEGVButton addTarget:self action:@selector(crashSignalEGVClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:crashSignalEGVButton];
    
    UIButton *crashSignalBRTButton = [[UIButton alloc] initWithFrame:CGRectMake(200, 350, 120, 100)];
    crashSignalBRTButton.backgroundColor = [UIColor redColor];
    [crashSignalBRTButton setTitle:@"Signal(ABRT)" forState:UIControlStateNormal];
    [crashSignalBRTButton addTarget:self action:@selector(crashSignalBRTClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:crashSignalBRTButton];
    
    UIButton *crashSignalBUSButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 350, 120, 100)];
    crashSignalBUSButton.backgroundColor = [UIColor redColor];
    [crashSignalBUSButton setTitle:@"Signal(BUS)" forState:UIControlStateNormal];
    [crashSignalBUSButton addTarget:self action:@selector(crashSignalBUSClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:crashSignalBUSButton];
}


- (void)crashSignalEGVClick
{
    //导致SIGSEGV的错误，一般会导致进程流产
    int *pi = (int *)0x00001111;
    *pi = 17;
}

- (void)crashSignalBRTClick
{
    
    Test *pTest = {1, 2};
    free(pTest); //导致SIGABRT的错误，因为内存中根本就没有这个空间，哪来的free，就在栈中的对象而已
    pTest->a = 5;
}

- (void)crashSignalBUSClick
{
    
    //SIGBUS，内存地址未对齐
    //EXC_BAD_ACCESS(code=1,address=0x1000dba58)
    char *s = "hello world";
    *s = 'H';
}

- (void)crashExcClick{
    
    [self performSelector:@selector(aaaa)];
}

@end
