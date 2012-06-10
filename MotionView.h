//
//  HoldingView.h
//  DraftingBoard
//
//  Created by Andy Lister on 10/10/11.
//  Copyright (c) 2011 plasticcube. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


// Panning options (pick one)
typedef enum 
{
    PanningOptionOn            = 1,  // Panning is on and view stays at where gesture finished.
    PanningOptionSlidingStop   = 2,  // Panning is on and view slides to stop with friction.
    PanningOptionOff           = 4,  // Panning is off.
    
} PanningOption;

typedef enum 
{
    TapOptionNoAnimation     = 8,
    TapOptionBounce          = 16
    
} TapOption;

typedef enum 
{
    RotateOptionOn           = 32,
    RotateOptionOff          = 64
    
} RotateOption;


typedef enum 
{
    PinchOptionOn           = 128,
    PinchOptionOff          = 256
    
} PinchOption;


@interface MotionView : UIView <UIGestureRecognizerDelegate>


// An options property that defines the pan and tap gesture characteristics
// Default is MotionOptionSliding | TapOptionBounce
@property (nonatomic, assign) int   options;

// Sets the friction value when sliding to a stop. 
// Default: 0.15
@property (nonatomic, assign) float friction;

// Sets how much the view scales during a bounce animation. 
// Default: 0.02
@property (nonatomic, assign) float bounceScale;

- (id)initWithFrame:(CGRect)frame options:(int)options;

@end
