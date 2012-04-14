//
//  MotionView.m
//  DraftingBoard
//
//  Created by Andy on 10/10/11.
//  Copyright (c) 2011 plasticcube. All rights reserved.
//

#import "MotionView.h"

#define FRICTION_DEFAULT 0.25f
#define BUMP_SCALE       0.01f
#define MIN_SCALE        0.5f


@interface MotionView ()

@property (nonatomic, assign) float angle;
@property (nonatomic, assign) float lastScale;
@property (nonatomic, assign) float friction;

@end


@implementation MotionView

@synthesize angle     = _angle;
@synthesize lastScale = _lastScale;
@synthesize friction  = _friction;
@synthesize options   = _options;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        self.backgroundColor = [UIColor clearColor];
        self.lastScale = 1.0;
        self.friction = FRICTION_DEFAULT; 
        
        UIRotationGestureRecognizer *rotateRecognizer = [[[UIRotationGestureRecognizer alloc] initWithTarget:self 
                                                                                                      action:@selector(didRotate:)] autorelease];
        rotateRecognizer.delegate = self;
        [self addGestureRecognizer:rotateRecognizer];
        
        UIPinchGestureRecognizer *pinchRecognizer = [[[UIPinchGestureRecognizer alloc] initWithTarget:self 
                                                                                               action:@selector(didPinch:)] autorelease];
        pinchRecognizer.delegate = self;
        [self addGestureRecognizer:pinchRecognizer];
        
        UIPanGestureRecognizer *panRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self 
                                                                                         action:@selector(didPan:)] autorelease];
        panRecognizer.delegate = self;
        [self addGestureRecognizer:panRecognizer];

        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangeOrientation:)
                                                     name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    }

    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[self superview].subviews indexOfObject:self] < [[self superview].subviews count]-1) 
    {
        if (self.options & TouchSelectBounce) 
            [self bounce];
        else
            [[self superview] bringSubviewToFront:self];
    }  
}

- (void)bounce 
{
    [UIView animateWithDuration:0.1 animations:^(void) {
        self.transform = CGAffineTransformScale(self.transform, self.lastScale+BUMP_SCALE, self.lastScale+BUMP_SCALE);
        [[self superview] bringSubviewToFront:self];
        
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^(void) {
            self.transform = CGAffineTransformScale(self.transform, self.lastScale-BUMP_SCALE, self.lastScale-BUMP_SCALE);
        }];
    }];
}

- (CGPoint)adjustForScreenRestraints:(CGPoint)input
{
    CGPoint output;
    
    float width = [UIScreen mainScreen].bounds.size.width;
    float height = [UIScreen mainScreen].bounds.size.height;
    
    if (input.x < 0)           output.x = 0; 			
    else if (input.x > width)  output.x = width;
    else                       output.x = input.x;
    
    if (input.y < 0)           output.y = 0; 			
    else if (input.y > height) output.y = height;
    else                       output.y = input.y;
    
    return output;
}

- (void)slideToPosition:(CGPoint)position
{
    CGPoint finish = [self adjustForScreenRestraints:position];
    
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^(void) {
        
        [self setCenter:CGPointMake(finish.x, finish.y)];
        
    } completion:^(BOOL finished) { }];
}

#pragma mark - UIGestureRecognizerDelegate


- (void)didPan:(UIPanGestureRecognizer *)sender 
{    
    [[self superview] bringSubviewToFront:self];
    
    if ([sender state] == UIGestureRecognizerStateBegan || [sender state] == UIGestureRecognizerStateChanged) 
    {
        CGPoint translation = [sender translationInView:[self superview]];
        self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
        
        [sender setTranslation:CGPointZero inView:[self superview]];
    }
    
    if ([sender state] == UIGestureRecognizerStateEnded) 
    {
        if (self.options & MotionSliding) 
        {
            CGPoint translation = [sender translationInView:[self superview]];
            CGPoint velocity = [sender velocityInView:[self superview]];
            CGPoint finish = CGPointMake(self.center.x + translation.x + (self.friction * velocity.x), 
                                             self.center.y + translation.y + (self.friction * velocity.y));
            [self slideToPosition:finish];
        }
    }
}

- (void)didRotate:(UIRotationGestureRecognizer *)sender 
{    
    [[self superview] bringSubviewToFront:self];
    
	if([sender state] == UIGestureRecognizerStateEnded) 
    {
		self.angle = 0.0;
		return;
	}
    
	CGFloat rotation = 0.0 - (self.angle - [sender rotation]);
    
	self.transform = CGAffineTransformRotate(self.transform, rotation);
	self.angle = [sender rotation];
}

- (void)didPinch:(UIPinchGestureRecognizer *)sender 
{
    [[self superview] bringSubviewToFront:self];
    
    if([sender state] == UIGestureRecognizerStateEnded) 
    {
        self.lastScale = 1.0;
    } 
    else 
    {
        CGFloat currentScale = [[self.layer valueForKeyPath:@"transform.scale"] floatValue] + ([sender scale] - self.lastScale);
        CGFloat scale = 1.0 - (self.lastScale - [sender scale]);
        
        if (currentScale > MIN_SCALE) 
        {
            self.transform = CGAffineTransformScale(self.transform, scale, scale);
            self.lastScale = [sender scale];
        }
    }
}

- (void)didTap:(UITapGestureRecognizer *)sender 
{    
    float scale = 0.01;
    
    [UIView animateWithDuration:0.05 animations:^(void) {
        
        self.transform = CGAffineTransformScale(self.transform, self.lastScale+scale, self.lastScale+scale);
        [[self superview] bringSubviewToFront:self];
        
    } completion:^(BOOL finished) {   
        
        [UIView animateWithDuration:0.05 animations:^(void) {
            self.transform = CGAffineTransformScale(self.transform, self.lastScale-scale, self.lastScale-scale);
        }];
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer 
{   
    return YES;
}

#pragma mark - UIDeviceOrientationDidChangeNotification

- (void)didChangeOrientation:(NSNotification *)notification
{

}

@end
