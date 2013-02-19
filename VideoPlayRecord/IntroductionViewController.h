//
//  IntroductionViewController.h
//  TwoPlus
//
//  Created by William Wu on 1/27/13.
//
//

#import <UIKit/UIKit.h>

@interface SmoothWhiteGradient : UIView
@end

@class IntroductionViewController;

@protocol IntroCompletedDelegate <NSObject>
- (void)introCompleted:(IntroductionViewController*)controller;
@end

@interface IntroductionViewController : UIViewController <UIScrollViewDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, weak) id<IntroCompletedDelegate> delegate;

+(BOOL)alreadyCompleted;
@end
