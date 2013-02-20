//
//  ViewController.h
//  VideoPlayRecord
//
//  Created by Abdul Azeem Khan on 5/9/12.
//  Copyright (c) 2012 DataInvent. All rights reserved.
//  Happy Coding

#import <UIKit/UIKit.h>
#import "iAd/iAd.h"
@interface ViewController : UIViewController <ADBannerViewDelegate>

@property (nonatomic, assign) BOOL bannerIsVisible;
@end
