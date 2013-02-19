//
//  TouchPassthroughView.m
//  TwoPlus
//
//  Created by William Wu on 1/15/13.
//
//

#import "TouchPassthroughView.h"

@implementation TouchPassthroughView {
    UIView* _targetView;
}

- (id)initWithFrame:(CGRect)frame andViewToPassthroughTo:(UIView*)targetView
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _targetView = targetView;
    }
    return self;
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    // If the hitView is THIS view, return nil and allow hitTest:withEvent: to
    // continue traversing the hierarchy to find the underlying view.
    if (hitView == self) {
        return _targetView;
    }
    // Else return the hitView (as it could be one of this view's buttons):
    return hitView;
}

@end
