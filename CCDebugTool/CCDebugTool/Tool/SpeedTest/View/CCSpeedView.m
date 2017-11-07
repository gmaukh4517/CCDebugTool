//
//  CCSpeedView.m
//  CCDebugTool
//
//  Created by CC on 2017/11/7.
//  Copyright © 2017年 CC. All rights reserved.
//

#import "CCSpeedView.h"

/** 开始位置 **/
static const CGFloat kStartAngle = 3.65;
/** 结束位置 **/
static const CGFloat kEndAngle = 0.51;

@interface CCSpeedView()

@property (nonatomic, assign) CGPoint speedCenter;
/** 记录刻度 **/
@property (nonatomic, strong) NSMutableArray *progressArray;
/** 内线进度条 **/
@property (nonatomic, strong) CAShapeLayer *progressLayer;
/** 速速值 **/
@property (nonatomic, strong) UILabel *speedLabel;
/** 单位 **/
@property (nonatomic, strong) UILabel *unitLabel;
@property (nonatomic, strong) UIColor *strokeColor;

@property (nonatomic, strong) CAReplicatorLayer *pulseLayer;
@property (nonatomic, strong) CALayer *effectLayer;
@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, strong) CAAnimationGroup *animationGroup;
@property (nonatomic, assign) NSTimeInterval pulseInterval;
@property (nonatomic, assign) NSInteger haloLayerNumber;
@end

@implementation CCSpeedView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initialization];
    }
    return self;
}

-(void)initialization
{
    _speedCenter = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    _strokeColor = [UIColor colorWithRed:0.22 green:0.66 blue:0.87 alpha:1.0];
    
    CGFloat abroadRadius = self.frame.size.width / 2 + 20;
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, abroadRadius, abroadRadius)];
    contentView.backgroundColor = [UIColor colorWithRed:0.098 green:0.5059 blue:0.862 alpha:1];
    contentView.layer.masksToBounds = YES;
    contentView.layer.cornerRadius = abroadRadius / 2;
    contentView.center = _speedCenter;
    [self addSubview:contentView];
    
    self.speedLabel.frame = CGRectMake((contentView.frame.size.width - 100) / 2, (contentView.frame.size.height - 40) / 2, 100, 20);
    self.unitLabel.frame = CGRectMake(self.speedLabel.frame.origin.x, self.speedLabel.frame.origin.y + self.speedLabel.frame.size.height, 100, 20);
    [contentView addSubview:self.speedLabel];
    [contentView addSubview:self.unitLabel];

    [self drawCicrle];
    [self drawCalibration];
    [self drawProgressCicrle];
    
    [self initPulse];
}

-(void)setSpeed:(NSString *)speed
{
    _speed = speed;
    self.speedLabel.text = speed;
}

-(void)setUnit:(NSString *)unit
{
    _unit = unit;
    self.unitLabel.text = unit;
}

-(void)setSpeedProgress:(float)speedProgress
{
    _speedProgress = speedProgress;
    [UIView animateWithDuration:0.2 animations:^{
        NSInteger index = round(speedProgress)<_progressArray.count?:_progressArray.count ;
        if (speedProgress <= 0)
            index = 0;

        for (NSInteger i = 0; i < _progressArray.count; i++) {
            CAShapeLayer *progressLayer = (CAShapeLayer *)[_progressArray objectAtIndex:i];
            UIColor *color = [UIColor whiteColor];
            if (i > index || index == 0) {
                color =  [UIColor colorWithRed:0.22 green:0.66 blue:0.87 alpha:1.0];
            }
            progressLayer.strokeColor = color.CGColor;
        }
        
        self.progressLayer.strokeEnd = speedProgress;
        if (speedProgress == 0) {
            self.progressLayer.strokeEnd = 0.001;
        }
    }];
    
}

#pragma mark -
#pragma mark :. speed dial
/** 画圆弧 **/
- (void)drawCicrle
{
    CGFloat abroadRadius = self.frame.size.width / 2;
    CGFloat withinRadius = abroadRadius - 40;
    
    //外线
    UIBezierPath *abroad = [UIBezierPath bezierPathWithArcCenter:_speedCenter radius:abroadRadius startAngle:-kStartAngle endAngle:kEndAngle clockwise:YES];
    CAShapeLayer *abroadLayer = [CAShapeLayer layer];
    abroadLayer.lineWidth = 1.0f;
    abroadLayer.fillColor = [UIColor clearColor].CGColor;
    abroadLayer.strokeColor = _strokeColor.CGColor;
    abroadLayer.path = abroad.CGPath;
    [self.layer addSublayer:abroadLayer];
    
    //内线
    UIBezierPath *within = [UIBezierPath bezierPathWithArcCenter:_speedCenter radius:withinRadius startAngle:-kStartAngle endAngle:kEndAngle clockwise:YES];
    CAShapeLayer *withinLayer = [CAShapeLayer layer];
    withinLayer.lineWidth = 1.0f;
    withinLayer.fillColor = [UIColor clearColor].CGColor;
    withinLayer.strokeColor = _strokeColor.CGColor;
    withinLayer.path = within.CGPath;
    [self.layer addSublayer:withinLayer];
}

/** 画刻度 **/
- (void)drawCalibration
{
    _progressArray = [NSMutableArray array];
    CGFloat tickRadius = self.frame.size.width / 2 - 20;
    
    CGFloat perAngle = (kStartAngle + kEndAngle) / 50;
    for (int i = 0; i < 51; i++) {
        CGFloat startAngel = (-kStartAngle + perAngle * i);
        CGFloat endAngel = startAngel + perAngle / 5;
        UIBezierPath *tickPath = [UIBezierPath bezierPathWithArcCenter:_speedCenter radius:tickRadius startAngle:startAngel endAngle:endAngel clockwise:YES];

        CAShapeLayer *perLayer = [CAShapeLayer layer];
        perLayer.strokeColor = _strokeColor.CGColor;
        perLayer.lineWidth = 5;
        if (i % 5 == 0)
            perLayer.lineWidth = 10.f;

        perLayer.path = tickPath.CGPath;
        [self.layer addSublayer:perLayer];
        [_progressArray addObject:perLayer];
    }
    
}

/** 进度的曲线 **/
- (void)drawProgressCicrle
{
    CGFloat progressRadius = self.frame.size.width / 2 - 40;
    UIBezierPath *progressPath  = [UIBezierPath bezierPathWithArcCenter:_speedCenter radius:progressRadius startAngle:-kStartAngle endAngle:kEndAngle clockwise:YES];
    
    CAShapeLayer *progressLayer = [CAShapeLayer layer];
    progressLayer.lineWidth = 2.0f;
    progressLayer.lineCap = kCALineCapRound;
    progressLayer.lineJoin = kCALineJoinRound;
    progressLayer.fillColor = [UIColor clearColor].CGColor;
    progressLayer.strokeColor = [UIColor whiteColor].CGColor;
    progressLayer.path = progressPath.CGPath;
    progressLayer.strokeStart = 0;
    progressLayer.strokeEnd = 1;
    progressLayer.strokeEnd = 0.001;
    [self.layer addSublayer:_progressLayer = progressLayer];
}

#pragma mark -
#pragma mark :. pulse

-(void)initPulse
{
    _animationDuration = 10;
    _pulseInterval = 1;
    _haloLayerNumber = 5;
    
    CGFloat radius = self.frame.size.width - 100;

    UIColor *color = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
    
    CAReplicatorLayer *pulseLayer = [CAReplicatorLayer new];
    pulseLayer.backgroundColor = color.CGColor;
    pulseLayer.instanceCount = _haloLayerNumber;
    pulseLayer.instanceDelay = (_animationDuration + _pulseInterval) / _haloLayerNumber;
    pulseLayer.instanceDelay = 1;
    pulseLayer.position = _speedCenter;
    [self.layer addSublayer:_pulseLayer = pulseLayer];

    CALayer *effect = [CALayer new];
    effect.contentsScale = [UIScreen mainScreen].scale;
    effect.opacity = 0;
    effect.backgroundColor = color.CGColor;
    [pulseLayer addSublayer:_effectLayer = effect];

    CGFloat diameter = radius * 2;
    effect.bounds = CGRectMake(0, 0, diameter, diameter);
    effect.cornerRadius = radius;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self setupAnimationGroup];
        if(self.pulseInterval != INFINITY) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.effectLayer addAnimation:self.animationGroup forKey:@"pulse"];
            });
        }
    });

    self.animationDuration = 5;
}

- (void)setAnimationDuration:(NSTimeInterval)animationDuration
{
    _animationDuration = animationDuration;
    self.animationGroup.duration = animationDuration + self.pulseInterval;
    for (CAAnimation *anAnimation in self.animationGroup.animations) {
        anAnimation.duration = animationDuration;
    }
    [self.effectLayer removeAllAnimations];
    [self.effectLayer addAnimation:self.animationGroup forKey:@"pulse"];
    self.pulseLayer.instanceDelay = (self.animationDuration + self.pulseInterval) / self.haloLayerNumber;
}

- (void)setupAnimationGroup
{
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.duration = self.animationDuration + self.pulseInterval;
    animationGroup.repeatCount = INFINITY;
    animationGroup.removedOnCompletion = NO;
    CAMediaTimingFunction *defaultCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    animationGroup.timingFunction = defaultCurve;
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
    scaleAnimation.fromValue = @(0.4);
    scaleAnimation.toValue = @1.0;
    scaleAnimation.duration = self.animationDuration;
    
    CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.duration = self.animationDuration;
    opacityAnimation.values = @[ @(0), @0.45, @0 ];
    opacityAnimation.keyTimes = @[ @0, @(0.2), @1 ];
    opacityAnimation.removedOnCompletion = NO;
    
    NSArray *animations = @[ scaleAnimation, opacityAnimation ];
    animationGroup.animations = animations;
    self.animationGroup = animationGroup;
}

#pragma mark -
#pragma mark :. getter/setter
-(UILabel *)speedLabel
{
    if (!_speedLabel) {
        UILabel *speedLabel = [[UILabel alloc] init];
        speedLabel.font = [UIFont systemFontOfSize:20];
        speedLabel.textAlignment = NSTextAlignmentCenter;
        speedLabel.textColor = [UIColor whiteColor];
        _speedLabel = speedLabel;
    }
    return _speedLabel;
}

-(UILabel *)unitLabel
{
    if (!_unitLabel) {
        UILabel *unitLabel = [[UILabel alloc] init];
        unitLabel.font = [UIFont systemFontOfSize:12];
        unitLabel.textAlignment = NSTextAlignmentCenter;
        unitLabel.textColor = [UIColor whiteColor];
        _unitLabel = unitLabel;
    }
    return _unitLabel;
}

@end
