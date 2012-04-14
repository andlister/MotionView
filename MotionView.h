//
//  HoldingView.h
//  DraftingBoard
//
//  Created by Andy Lister on 10/10/11.
//  Copyright (c) 2011 plasticcube. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum 
{
    MotionStatic            = 1,
    MotionSliding           = 2,
    
} MotionOptions;

typedef enum 
{
    TouchSelectNoAnimation  = 4,
    TouchSelectBounce       = 8
    
} TouchSelectOptions;


@interface MotionView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, assign) int   options;

- (void)bounce;

@end
