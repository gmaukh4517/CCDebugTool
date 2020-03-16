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
    
    CGFloat spacing = 10;
    
    NSInteger rowNumber = 2;
    CGFloat x = spacing,y = 20;
    CGFloat width = (self.view.bounds.size.width - 10 * (rowNumber + 1)) / rowNumber;
    
    NSArray *arr = @[@"Exception" , @"Signal(EGV)" , @"Signal(ABRT)" , @"Signal(BUS)"];
    
    for (NSInteger i = 0; i < arr.count; i++) {
        UIButton *crashButton = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, width)];
        crashButton.backgroundColor = [UIColor redColor];
        crashButton.tag = i;
        [crashButton setTitle:[arr objectAtIndex:i] forState:UIControlStateNormal];
        [crashButton addTarget:self action:@selector(crashButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:crashButton];
        
        x = crashButton.frame.origin.x + crashButton.frame.size.width + spacing;
        if ( (i + 1) % rowNumber == 0) {
            x = spacing;
            y += crashButton.bounds.size.height + spacing;
        }
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

}

-(void)crashButtonClick:(UIButton *)sender
{
    if (sender.tag == 0) {
        [self crashExcClick];
    }else if (sender.tag == 1){
        [self crashSignalEGVClick];
    }else if (sender.tag == 2){
        [self crashSignalBRTClick];
    }else if (sender.tag == 3){
        [self crashSignalBUSClick];
    }
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
