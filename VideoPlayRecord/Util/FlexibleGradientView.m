//
//  WhiteGradientView.m
//  TwoPlus
//
//  Created by William Wu on 1/15/13.
//
//

#import "FlexibleGradientView.h"
#import <QuartzCore/QuartzCore.h>

@implementation FlexibleGradientView

- (id)initWithFrame:(CGRect)frame andViewToPassthroughTo:(UIView*)targetView
{
    self = [super initWithFrame:frame andViewToPassthroughTo:targetView];
    if (self) {
        // Initialization code
    }
    return self;
}

+(Class) layerClass {
    return [CAGradientLayer class];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
