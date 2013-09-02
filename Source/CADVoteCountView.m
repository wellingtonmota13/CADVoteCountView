//
//  CADVoteCountView.m
//  Gossip
//
//  Created by Joan Romano on 10/05/13.
//  Copyright (c) 2013 Oriol Blanc. All rights reserved.
//

#import "CADVoteCountView.h"

#import <QuartzCore/QuartzCore.h>

static NSUInteger const kMaxAngle = 360;
static NSUInteger const kActualMaxAngle = 343;

static CGFloat const kMinHSLValue = 100.0f;
static CGFloat const kMaxHSLValue = 340.0f;

static CGFloat const kPaddingArea = 3.0f;
static CGFloat const kAnimationDuration = 0.5f;
static CGFloat const kDefaultColorLineWidthRatio = 6.0f;
static CGFloat const kDefaultBackgroundLineWidthRatio = 4.0f;

@interface CADVoteCountView ()

@property (nonatomic) NSUInteger radius;
@property (nonatomic, strong) CAShapeLayer *colorPathLayer;
@property (nonatomic, strong) CAShapeLayer *backgroundLayer;
@property (nonatomic, strong) CAAnimationGroup *colorPathGroupAnimation;
@property (nonatomic, strong) CAKeyframeAnimation *colorPathStrokeEndAnimation;
@property (nonatomic, strong) CAKeyframeAnimation *colorPathStrokeColorAnimation;

- (void)setupView;
- (void)updateColorPath;

- (UIColor *)colorFromCurrentAngle;
- (UIColor *)colorFromAngle:(NSUInteger)angle;

- (UIColor *)defaultBackgroundLayerColor;

CGMutablePathRef createFullArcWithStartingAngleAndRadius(CGRect rect, long double angle, CGFloat radius, long double endAngle);

@end

@implementation CADVoteCountView

@synthesize colorLineWidthRatio = _colorLineWidthRatio;
@synthesize backgroundLineWidthRatio = _backgroundLineWidthRatio;

#pragma mark - Class Methods

+ (NSUInteger)maxAngle
{
    return kMaxAngle;
}

#pragma mark - Overridden Methods

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setupView];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _radius = (CGRectGetWidth(self.frame)/2) - kPaddingArea;
    
    // Background drawing
    [self.layer addSublayer:self.backgroundLayer];
    
    // Colored count drawing
    [self.layer addSublayer:self.colorPathLayer];
}

#pragma mark - Lazy

- (CAShapeLayer *)backgroundLayer
{
    if (!_backgroundLayer)
    {        
        _backgroundLayer = [CAShapeLayer layer];
        _backgroundLayer.fillColor = nil;
        _backgroundLayer.lineCap = kCALineCapButt;
    }
    
    _backgroundLayer.strokeColor = self.backgroundLayerColor ?
                                   self.backgroundLayerColor.CGColor : [self defaultBackgroundLayerColor].CGColor;
    _backgroundLayer.lineWidth = CGRectGetWidth(self.bounds) / (self.backgroundLineWidthRatio > 0.0f ?
                                                                self.backgroundLineWidthRatio : kDefaultBackgroundLineWidthRatio);
    _backgroundLayer.path = createFullArcWithStartingAngleAndRadius(self.frame, M_PI_2, self.radius, M_PI_2 + (M_PI * 2));
    
    return _backgroundLayer;
}

- (CAShapeLayer *)colorPathLayer
{
    if (!_colorPathLayer)
    {
        _colorPathLayer = [CAShapeLayer layer];
        _colorPathLayer.fillColor = nil;
        _colorPathLayer.lineCap = kCALineCapRound;
        _colorPathLayer.strokeColor = [self colorFromCurrentAngle].CGColor;
        _colorPathLayer.strokeEnd = self.angle / 360.0;
    }
    
    _colorPathLayer.lineWidth = CGRectGetWidth(self.bounds) / (self.colorLineWidthRatio > 0.0f ?
                                                               self.colorLineWidthRatio : kDefaultColorLineWidthRatio);
    _colorPathLayer.path = createFullArcWithStartingAngleAndRadius(self.frame, M_PI_2, self.radius, M_PI_2 + (([CADVoteCountView maxAngle] * M_PI)/180));
    
    return _colorPathLayer;
}

- (CAAnimationGroup *)colorPathGroupAnimation
{
    if (!_colorPathGroupAnimation)
    {
        _colorPathGroupAnimation = [CAAnimationGroup animation];
        _colorPathGroupAnimation.animations = @[self.colorPathStrokeColorAnimation, self.colorPathStrokeEndAnimation];
        _colorPathGroupAnimation.duration = kAnimationDuration;
    }
    
    return _colorPathGroupAnimation;
}

- (CAKeyframeAnimation *)colorPathStrokeColorAnimation
{
    if (!_colorPathStrokeColorAnimation)
    {
        _colorPathStrokeColorAnimation = [CAKeyframeAnimation animationWithKeyPath:@"strokeColor"];
        _colorPathStrokeColorAnimation.duration = kAnimationDuration;
    }
    
    return _colorPathStrokeColorAnimation;
}

- (CAKeyframeAnimation *)colorPathStrokeEndAnimation
{
    if (!_colorPathStrokeEndAnimation)
    {
        _colorPathStrokeEndAnimation = [CAKeyframeAnimation animationWithKeyPath:@"strokeEnd"];
        _colorPathStrokeEndAnimation.duration = kAnimationDuration;
    }
    
    return _colorPathStrokeEndAnimation;
}

#pragma mark - Private Methods

CGMutablePathRef createFullArcWithStartingAngleAndRadius(CGRect rect, long double angle, CGFloat radius, long double endAngle)
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddArc(path, NULL, CGRectGetWidth(rect)/2  , CGRectGetHeight(rect)/2, radius, angle, endAngle, 0);
    
    return path;
}

- (void)updateColorPath
{
    self.colorPathLayer.strokeColor = [self colorFromCurrentAngle].CGColor;
    self.colorPathLayer.strokeEnd = self.angle / 360.0;
}

- (void)setupView
{
    _radius = (CGRectGetWidth(self.frame)/2) - kPaddingArea;
    _angle = 180;
}

- (UIColor *)colorFromCurrentAngle
{
    return [self colorFromAngle:self.angle];
}

- (UIColor *)colorFromAngle:(NSUInteger)angle
{
    CGFloat green = ((CGFloat)angle / ((CGFloat)360 -1));
    CGFloat red = (- 1 / ((CGFloat)360 - 1) * (CGFloat)angle) + 1;
    
    return [UIColor colorWithRed:red green:green blue:0 alpha:1];
}

- (UIColor *)defaultBackgroundLayerColor
{
    return [UIColor colorWithRed:68.0f/255.0f green:68.0f/255.0f blue:68.0f/255.0f alpha:1.0f];
}

#pragma mark - Public Methods

- (void)setAngle:(NSUInteger)angle
{
    [self setAngle:angle bouncing:NO];
}

- (void)setAngle:(NSUInteger)angle bouncing:(BOOL)bouncing
{
    if (angle>[CADVoteCountView maxAngle])
        return;
    
    if (angle>kActualMaxAngle)
    {
        angle = kActualMaxAngle;
    }
    
    CGFloat alpha = angle > _angle ? angle*1.2f : angle*0.8f;
    
    self.colorPathStrokeEndAnimation.values = @[[NSNumber numberWithFloat:(CGFloat) (_angle / 360.0)],
                                                [NSNumber numberWithFloat:(CGFloat) (alpha / 360.0)],
                                                [NSNumber numberWithFloat:(CGFloat) (angle / 360.0)]];
    
    self.colorPathStrokeColorAnimation.values = @[(id)[self colorFromAngle:_angle].CGColor,
                                                  (id)[self colorFromAngle:alpha].CGColor,
                                                  (id)[self colorFromAngle:angle].CGColor];
    
    _angle = angle;
    [self updateColorPath];
    
    if (bouncing)
    {
        [self.colorPathLayer addAnimation:self.colorPathGroupAnimation forKey:@"strokePathAnimation"];
    }
}

- (CGFloat)colorLineWidthRatio
{
    return _colorLineWidthRatio > 0.0f ? _colorLineWidthRatio : kDefaultColorLineWidthRatio;
}

- (void)setColorLineWidthRatio:(CGFloat)colorLineWidthRatio
{
    if (colorLineWidthRatio <= 0.0f)
        return;
    
    _colorLineWidthRatio = colorLineWidthRatio;
    [self setNeedsLayout];
}

- (CGFloat)backgroundLineWidthRatio
{
    return _backgroundLineWidthRatio > 0.0f ? _backgroundLineWidthRatio : kDefaultBackgroundLineWidthRatio;
}

- (void)setBackgroundLineWidthRatio:(CGFloat)backgroundLineWidthRatio
{
    if (backgroundLineWidthRatio <= 0.0f)
        return;
    
    _backgroundLineWidthRatio = backgroundLineWidthRatio;
    [self setNeedsLayout];
}

- (void)setBackgroundLayerColor:(UIColor *)backgroundLayerColor
{
    _backgroundLayerColor = backgroundLayerColor;
    
    [self setNeedsLayout];
}

@end