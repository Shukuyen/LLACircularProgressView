//
//  LLACircularProgressView.m
//  LLACircularProgressView
//
//  Created by Lukas Lipka on 26/10/13.
//  Copyright (c) 2013 Lukas Lipka. All rights reserved.
//

#import "LLACircularProgressView.h"
#import <QuartzCore/QuartzCore.h>
#import <Availability.h>

@interface LLACircularProgressView ()

@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation LLACircularProgressView

@synthesize progressTintColor = _progressTintColor;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.contentMode = UIViewContentModeRedraw;
    self.backgroundColor = [UIColor whiteColor];

    _progressTintColor = [UIColor blackColor];
    _ringColor = [UIColor blackColor];
    
    _progressLayer = [[CAShapeLayer alloc] init];
    _progressLayer.strokeColor = self.progressTintColor.CGColor;
    _progressLayer.strokeEnd = 0;
    _progressLayer.fillColor = nil;
    _progressLayer.lineWidth = 3;
    [self.layer addSublayer:_progressLayer];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.progressLayer.frame = self.bounds;
    
    [self updatePath];
}

- (void)drawRect:(CGRect)rect {
    CGFloat diameter = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    CGRect circleBounds = CGRectMake(CGRectGetMidX(self.bounds) - (diameter / 2),
                                     CGRectGetMidY(self.bounds) - (diameter / 2),
                                     diameter,
                                     diameter);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (self.ringColor) {
        CGContextSetFillColorWithColor(ctx, self.ringColor.CGColor);
        CGContextSetStrokeColorWithColor(ctx, self.ringColor.CGColor);
        CGContextStrokeEllipseInRect(ctx, CGRectInset(circleBounds, self.padding, self.padding));
    }
    
    CGContextSetFillColorWithColor(ctx, self.progressTintColor.CGColor);
    CGContextSetStrokeColorWithColor(ctx, self.progressTintColor.CGColor);
    
    if (!self.imageView.image) {
        CGRect stopRect;
        stopRect.origin.x = CGRectGetMidX(circleBounds) - circleBounds.size.width / 8;
        stopRect.origin.y = CGRectGetMidY(circleBounds) - circleBounds.size.height / 8;
        stopRect.size.width = circleBounds.size.width / 4;
        stopRect.size.height = circleBounds.size.height / 4;
        CGContextFillRect(ctx, CGRectIntegral(stopRect));        
    }
}

#pragma mark - Accessors

- (void)setProgress:(float)progress {
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(float)progress animated:(BOOL)animated {
    if (progress > 0) {
        if (animated) {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            animation.fromValue = self.progress == 0 ? @0 : nil;
            animation.toValue = [NSNumber numberWithFloat:progress];
            animation.duration = 1;
            self.progressLayer.strokeEnd = progress;
            [self.progressLayer addAnimation:animation forKey:@"animation"];
        } else {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            self.progressLayer.strokeEnd = progress;
            [CATransaction commit];
        }
    } else {
        self.progressLayer.strokeEnd = 0.0f;
        [self.progressLayer removeAnimationForKey:@"animation"];
    }
    
    _progress = progress;
}

- (void)setProgress:(float)progress duration:(NSTimeInterval)duration completion:(void(^)(LLACircularProgressView *progressView))completion {

    if (progress > 0) {
        [CATransaction begin];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.fromValue = self.progress == 0 ? @0 : nil;
        animation.toValue = [NSNumber numberWithFloat:progress];
        animation.duration = duration;
        [CATransaction setCompletionBlock:^{
            completion(self);
        }];
        self.progressLayer.strokeEnd = progress;
        [self.progressLayer addAnimation:animation forKey:@"animation"];
        [CATransaction commit];
    } else {
        self.progressLayer.strokeEnd = 0.0f;
        [self.progressLayer removeAnimationForKey:@"animation"];
    }

    _progress = progress;

}

- (void)setIcon:(UIImage *)icon
{
    [self setIcon:icon animated:NO];
}

- (void)setIcon:(UIImage *)icon animated:(BOOL)animated
{
    if (!self.imageView) {
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.contentMode = UIViewContentModeCenter;
        [self addSubview:self.imageView];
    }
    
    [UIView animateWithDuration:animated ? 0.3f : 0.0f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.imageView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.imageView setImage:icon];
        [UIView animateWithDuration:animated ? 0.3f : 0.0f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.imageView.alpha = 1.0f;
        } completion:^(BOOL finished) {
            [self setNeedsDisplay];
        }];
    }];
}

- (UIColor *)progressTintColor {
#ifdef __IPHONE_7_0
    if ([self respondsToSelector:@selector(tintColor)]) {
        return self.tintColor;
    }
#endif
    return _progressTintColor;
}

- (void)setProgressTintColor:(UIColor *)progressTintColor {
#ifdef __IPHONE_7_0
    if ([self respondsToSelector:@selector(setTintColor:)]) {
        self.tintColor = progressTintColor;
        return;
    }
#endif
    _progressTintColor = progressTintColor;
    self.progressLayer.strokeColor = progressTintColor.CGColor;
    [self setNeedsDisplay];
}

#pragma mark - Other

#ifdef __IPHONE_7_0
- (void)tintColorDidChange {
    [super tintColorDidChange];
    
    self.progressLayer.strokeColor = self.tintColor.CGColor;
    [self setNeedsDisplay];
}
#endif

#pragma mark - Private

- (void)updatePath {
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat radius = (MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) / 2) - 2 - self.padding;
    self.progressLayer.path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:-M_PI_2 endAngle:-M_PI_2 + 2 * M_PI clockwise:YES].CGPath;
}

@end
