//
//  ViewController.m
//  VideoPlayRecord
//
//  Created by Abdul Azeem Khan on 5/9/12.
//  Copyright (c) 2012 DataInvent. All rights reserved.
//

#import "ViewController.h"
#import "IntroductionViewController.h"

#import "OLImageView.h"
#import "OLImage.h"


@implementation ViewController {
    ADBannerView* _adView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _adView.hidden = YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    OLImageView *Aimv = [OLImageView new];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"harlemshake" ofType:@"gif"];
    NSData *GIFDATA = [NSData dataWithContentsOfFile:filePath];
    Aimv.image = [OLImage imageWithData:GIFDATA];
    [Aimv setFrame:self.view.bounds];
    Aimv.contentMode = UIViewContentModeScaleAspectFill;
    Aimv.clipsToBounds = YES;
    [self.view addSubview:Aimv];
    
    UIButton* newShakeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    newShakeButton.backgroundColor = [UIColor colorWithRed:33.0f/255.0f green:136.0f/255.0f blue:233.0f/255.0f alpha:1.0f];
    newShakeButton.frame = CGRectMake(20, 140, 280, 50);
    [newShakeButton addTarget:self action:@selector(newShake:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel* buttonText3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, newShakeButton.frame.size.width, newShakeButton.frame.size.height)];
    buttonText3.center = CGPointMake(newShakeButton.frame.size.width/2, newShakeButton.frame.size.height/2);
    buttonText3.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25.0f];
    buttonText3.text = @"Make a shake";
    buttonText3.textColor = [UIColor whiteColor];
    buttonText3.textAlignment = UITextAlignmentCenter;
    buttonText3.backgroundColor = [UIColor clearColor];
    [newShakeButton addSubview:buttonText3];
    [self.view addSubview:newShakeButton];
    
    UIButton* itunesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    itunesButton.backgroundColor = [UIColor colorWithRed:33.0f/255.0f green:136.0f/255.0f blue:233.0f/255.0f alpha:1.0f];
    itunesButton.frame = CGRectMake(20, 200, 280, 50);
    [itunesButton addTarget:self action:@selector(gotoItunes:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel* buttonText2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, newShakeButton.frame.size.width, newShakeButton.frame.size.height)];
    buttonText2.center = CGPointMake(newShakeButton.frame.size.width/2, newShakeButton.frame.size.height/2);
    buttonText2.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25.0f];
    buttonText2.text = @"Buy the song in iTunes";
    buttonText2.textColor = [UIColor whiteColor];
    buttonText2.textAlignment = UITextAlignmentCenter;
    buttonText2.backgroundColor = [UIColor clearColor];
    [itunesButton addSubview:buttonText2];
    [self.view addSubview:itunesButton];
    
    _adView = [[ADBannerView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, 0, 0)];
    _adView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
    _adView.delegate = self;
    [self.view addSubview:_adView];
    
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    banner.hidden = YES;
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    if (!self.bannerIsVisible)
    {
        [UIView beginAnimations:@"animateAdBannerOn" context:NULL];
        // Assumes the banner view is just off the bottom of the screen.
        banner.frame = CGRectOffset(banner.frame, 0, -banner.frame.size.height);
        [UIView commitAnimations];
        self.bannerIsVisible = YES;
    }
}

-(void)gotoItunes:(UIButton*)button {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/album/harlem-shake-single/id601136812?uo=4"]];
}

-(void)newShake:(UIButton*)button {
    IntroductionViewController* introVC = [[IntroductionViewController alloc] init];
    introVC.delegate = self;
    [self presentViewController:introVC animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
