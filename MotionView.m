//
//  MotionView.m
//  DraftingBoard
//
//  Created by Andy on 10/10/11.
//  Copyright (c) 2011 plasticcube. All rights reserved.
//

#import "MotionView.h"

#define FRICTION_DEFAULT      0.25f
#define BOUNCE_SCALE_DEFAULT  0.02f
#define MIN_SCALE_DEFAULT     0.5f

#define DEBUG_LOG   1

@interface MotionView ()

@property (nonatomic) float                       angle;
@property (nonatomic) float                       lastScale;
@property (nonatomic) UIRotationGestureRecognizer *rotateRecognizer;
@property (nonatomic) UIPinchGestureRecognizer    *pinchRecognizer;
@property (nonatomic) UIPanGestureRecognizer      *panRecognizer;

@end


@implementation MotionView

@synthesize angle            = _angle;
@synthesize lastScale        = _lastScale;
@synthesize friction         = _friction;
@synthesize options          = _options;
@synthesize bounceScale      = _bounceScale;
@synthesize rotateRecognizer = _rotateRecognizer;
@synthesize pinchRecognizer  = _pinchRecognizer;
@synthesize panRecognizer    = _panRecognizer;


- (id)initWithFrame:(CGRect)frame options:(int)options
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        self.backgroundColor = [UIColor clearColor];
        self.lastScale = 1.0;
        self.friction = FRICTION_DEFAULT; 
        self.bounceScale = BOUNCE_SCALE_DEFAULT;
            
        self.rotateRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self 
                                                                              action:@selector(didRotate:)];
        self.rotateRecognizer.delegate = self;
            
        self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self 
                                                                          action:@selector(didPinch:)];
        self.pinchRecognizer.delegate = self;
            
        self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self 
                                                                      action:@selector(didPan:)];
        self.panRecognizer.delegate = self;
        
        self.options = options;
        
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(didChangeOrientation:)
//                                                     name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    }
    
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame options:(PanningOptionSlidingStop | TapOptionBounce | PinchOptionOn | RotateOptionOn)];
}




- (void)setOptions:(int)options
{
    [self removeGestureRecognizer:self.rotateRecognizer];
    [self removeGestureRecognizer:self.panRecognizer];
    [self removeGestureRecognizer:self.pinchRecognizer];
    
    _options = options;
    
    if (((self.options & PanningOptionOff) != PanningOptionOff)) {
        [self addGestureRecognizer:self.panRecognizer];
    }

    if ((self.options & RotateOptionOff) != RotateOptionOff) {
        [self addGestureRecognizer:self.rotateRecognizer];
    }
    
    if (!(self.options & PinchOptionOff) != PinchOptionOff) {
        [self addGestureRecognizer:self.pinchRecognizer];
    }
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[self superview].subviews indexOfObject:self] < [[self superview].subviews count]-1) 
    {
        if (self.options & TapOptionBounce) 
            [self bounce];
        else
            [[self superview] bringSubviewToFront:self];
    }  
}


- (void)bounce 
{
    CGAffineTransform currentTransform = self.transform;
    
    [UIView animateWithDuration:0.2 animations:^(void) {
        DLog(@"\nself.lastScale = %f\nself.bounceScale = %f\n", self.lastScale, self.bounceScale);
        self.transform = CGAffineTransformScale(self.transform,
                                                self.lastScale + self.bounceScale,
                                                self.lastScale + self.bounceScale);
        [[self superview] bringSubviewToFront:self];
        
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^(void) {
            self.transform = currentTransform;
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
        if (self.options & PanningOptionSlidingStop) 
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
        
        if (currentScale > MIN_SCALE_DEFAULT) 
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


@end
