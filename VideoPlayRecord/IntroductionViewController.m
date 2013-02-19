//
//  IntroductionViewController.m
//  TwoPlus
//
//  Created by William Wu on 1/27/13.
//
//

#import "IntroductionViewController.h"
#import "DDPageControl.h"
#import "FlexibleGradientView.h"
#import <QuartzCore/QuartzCore.h>

#define kCurrentIntroVersion 1
#define kIntroVersionFinished @"IntroVersionAlreadyFinished"
#define CORNER_RADIUS 7.0f
#define kNumberOfIntroPages 5.0f
#define kForegroundToBackgroundScrollFactor 6.0f

@implementation SmoothWhiteGradient

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
- (void)drawRect:(CGRect)rect
{
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    CGGradientRef glossGradient;
    CGColorSpaceRef rgbColorspace;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = { 1.0, 1.0, 1.0, 1.0,  // Start color
        213.0f/255.0f, 211.0f/255.0f, 211.0f/255.0f, 1.0 }; // End color
    
    rgbColorspace = CGColorSpaceCreateDeviceRGB();
    glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, num_locations);
    
    CGRect currentBounds = self.bounds;
    CGPoint topCenter = CGPointMake(CGRectGetMidX(currentBounds), 0.0f);
    CGPoint midCenter = CGPointMake(CGRectGetMidX(currentBounds), currentBounds.origin.y + currentBounds.size.height);
    CGContextDrawLinearGradient(currentContext, glossGradient, topCenter, midCenter, 0);
    
    CGGradientRelease(glossGradient);
    CGColorSpaceRelease(rgbColorspace);
}

@end

@interface IntroductionViewController () {
    UIColor* _orangeColor;
    DDPageControl* _pageControl;
    UIScrollView* _backgroundScrollView;
    UIScrollView* _foregroundScrollView;
    SmoothWhiteGradient* _smoothGradient;
    
    UIButton* _getStartedButton;
    FlexibleGradientView* _getStartedButtonDepressedOverlay;
}

@end

@implementation IntroductionViewController

- (id)init
{
    self = [super init];
    if (self) {
        _orangeColor = [UIColor colorWithRed:243.0f/255.0f green:162.0f/255.0f blue:63.0f/255.0f alpha:1.0f];
        self.view.layer.cornerRadius = CORNER_RADIUS;
        self.view.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
        
        // Put a gradient over the solid background
        _smoothGradient = [[SmoothWhiteGradient alloc] initWithFrame:self.view.bounds];
        _smoothGradient.layer.cornerRadius = CORNER_RADIUS;
        _smoothGradient.clipsToBounds = YES;
        _smoothGradient.alpha = 0.9;
        
        CGFloat foregroundWidth = self.view.bounds.size.width * kNumberOfIntroPages;
        //CGFloat uncorrectedBackgroundWidth = foregroundWidth / kForegroundToBackgroundScrollFactor;
        //CGFloat test = (foregroundWidth - uncorrectedBackgroundWidth) / kNumberOfIntroPages;
        CGFloat backgroundWidthCorrection = self.view.bounds.size.width*(1.0f-1.0f/kForegroundToBackgroundScrollFactor);
        
        _backgroundScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _backgroundScrollView.layer.cornerRadius = CORNER_RADIUS;
        _backgroundScrollView.backgroundColor = [UIColor clearColor];
        _backgroundScrollView.contentSize = CGSizeMake((foregroundWidth/kForegroundToBackgroundScrollFactor)+backgroundWidthCorrection, self.view.bounds.size.height);
        _backgroundScrollView.scrollEnabled = NO;
        _backgroundScrollView.showsHorizontalScrollIndicator = NO;
        
        _foregroundScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _foregroundScrollView.delegate = self;
        _foregroundScrollView.layer.cornerRadius = CORNER_RADIUS;
        _foregroundScrollView.backgroundColor = [UIColor clearColor];
        _foregroundScrollView.contentSize = CGSizeMake(foregroundWidth, self.view.bounds.size.height);
        _foregroundScrollView.pagingEnabled = YES;
        _foregroundScrollView.showsHorizontalScrollIndicator = NO;
        _foregroundScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
        
        // Initialize the page dots
        _pageControl = [[DDPageControl alloc] init] ;
        [_pageControl setNumberOfPages: kNumberOfIntroPages];
        [_pageControl setCurrentPage: 0];
        [_pageControl setDefersCurrentPageDisplay: NO];
        [_pageControl setType: DDPageControlTypeOnFullOffFull];
        [_pageControl setOnColor: _orangeColor];
        [_pageControl setOffColor: [UIColor colorWithWhite: 1.0f alpha: 0.9f]] ;
        [_pageControl setIndicatorDiameter: 6.0f];
        [_pageControl setIndicatorSpace: 6.0f];
        _pageControl.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height - 15);
        
        [self.view addSubview:_backgroundScrollView];
        [self.view addSubview:_smoothGradient];
        [self.view addSubview:_foregroundScrollView];
        [self.view addSubview:_pageControl];

        [self populateScrollViews];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)populateScrollViews
{
    // Setup the background image
    UIImageView* background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"introBackgroundAwesome.jpg"]];
    background.contentMode = UIViewContentModeScaleAspectFill;
    background.clipsToBounds = YES;
    
    CGFloat overscanCorrection = _foregroundScrollView.frame.size.width / kForegroundToBackgroundScrollFactor;
    background.frame = CGRectMake(-overscanCorrection, 0, _backgroundScrollView.contentSize.width + 2*overscanCorrection, _backgroundScrollView.frame.size.height/**2/3*/);
    [_backgroundScrollView addSubview:background];
    
    // Setup the first page
    UIImageView* logo1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"2plusLogo.png"]];
    logo1.contentMode = UIViewContentModeScaleAspectFit;
    logo1.center = CGPointMake(self.view.bounds.size.width/2 + 10, 100);
    [_foregroundScrollView addSubview:logo1];
    
    
    
    // Setup the second page
    
// Save this stuff for when we actually release the editor
//    UIImageView* successKid = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sticker15.png"]];
//    successKid.contentMode = UIViewContentModeScaleAspectFit;
//    successKid.frame = CGRectMake(0, 0, self.view.bounds.size.width, 220);
//    successKid.center = CGPointMake(self.view.bounds.size.width*(1)+self.view.bounds.size.width/2-38, self.view.bounds.size.height-100);
//    [_foregroundScrollView addSubview:successKid];
//    
//    UIImageView* leo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sticker12.png"]];
//    leo.contentMode = UIViewContentModeScaleAspectFit;
//    leo.frame = CGRectMake(0, 0, self.view.bounds.size.width, 150);
//    leo.center = CGPointMake(self.view.bounds.size.width*(1)+self.view.bounds.size.width/2+100, self.view.bounds.size.height-70);
//    [_foregroundScrollView addSubview:leo];
//
//    UIImageView* shareEverything = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sticker20.png"]];
//    shareEverything.contentMode = UIViewContentModeScaleAspectFit;
//    shareEverything.frame = CGRectMake(0, 0, self.view.bounds.size.width, 200);
//    shareEverything.center = CGPointMake(self.view.bounds.size.width*(1)+self.view.bounds.size.width/2+5, 80);
//    shareEverything.transform = CGAffineTransformMakeRotation(3.14159);
//    [_foregroundScrollView addSubview:shareEverything];
    
    UIImageView* funnyFace = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shareWhatever.png"]];
    funnyFace.contentMode = UIViewContentModeScaleAspectFit;
    funnyFace.alpha = 0.9f;
    funnyFace.frame = CGRectMake(0, 0, self.view.bounds.size.width-25, self.view.bounds.size.height-40);
    funnyFace.center = CGPointMake(self.view.bounds.size.width*(1)+self.view.bounds.size.width/2, self.view.bounds.size.height/2-50);
    [_foregroundScrollView addSubview:funnyFace];
    
//    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(label1.center.x - 12, label1.frame.origin.y + 71, 110, 6)];
//    lineView.backgroundColor = [UIColor orangeColor];
//    lineView.layer.cornerRadius = 3.0f;
//    lineView.layer.borderColor = [UIColor whiteColor].CGColor;
//    lineView.layer.borderWidth = 2.0f;
//    [_foregroundScrollView addSubview:lineView];
    
    
    // Setup the third page
    UIImageView* playTogether = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"playTogether.png"]];
    playTogether.contentMode = UIViewContentModeScaleAspectFit;
    playTogether.frame = CGRectMake(0, 0, self.view.bounds.size.width-20, self.view.bounds.size.height);
    playTogether.center = CGPointMake(self.view.bounds.size.width*(2)+self.view.bounds.size.width/2-12, self.view.bounds.size.height/2-50);
    [_foregroundScrollView addSubview:playTogether];

    
    
    // Setup the fourth page
    UIImageView* chatWherever = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatWherever.png"]];
    chatWherever.contentMode = UIViewContentModeScaleAspectFill;
    chatWherever.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    chatWherever.center = CGPointMake(self.view.bounds.size.width*(3)+self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    [_foregroundScrollView addSubview:chatWherever];
        
    // Setup the fifth (final) page
    UIImageView* logo2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"2plusLogo.png"]];
    logo2.contentMode = UIViewContentModeScaleAspectFit;
    logo2.center = CGPointMake(self.view.bounds.size.width*(kNumberOfIntroPages-1)+self.view.bounds.size.width/2 + 10, 100);
    [_foregroundScrollView addSubview:logo2];
    
    _getStartedButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _getStartedButton.backgroundColor = [UIColor colorWithRed:33.0f/255.0f green:136.0f/255.0f blue:233.0f/255.0f alpha:1.0f];
    _getStartedButton.frame = CGRectMake(0, 0, 280, 50);
    _getStartedButton.center = CGPointMake(self.view.bounds.size.width*(kNumberOfIntroPages-1)+self.view.bounds.size.width/2, _foregroundScrollView.frame.size.height/2);
    [_getStartedButton addTarget:self action:@selector(getStarted:) forControlEvents:UIControlEventTouchUpInside];
    [_getStartedButton addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
    [_getStartedButton addTarget:self action:@selector(buttonCancel:) forControlEvents:UIControlEventTouchDragOutside];
    [_getStartedButton addTarget:self action:@selector(buttonCancel:) forControlEvents:UIControlEventTouchCancel];
    
    _getStartedButton.clipsToBounds = YES;
    _getStartedButton.layer.borderColor = [UIColor whiteColor].CGColor;
    _getStartedButton.layer.borderWidth = 3.0;
    _getStartedButton.layer.cornerRadius = 10.0f;
    
    UIView* shadow = [[UIView alloc] initWithFrame:_getStartedButton.frame];
    shadow.backgroundColor = [UIColor whiteColor];
    shadow.layer.cornerRadius = _getStartedButton.layer.cornerRadius;
    shadow.layer.shadowColor = [UIColor blackColor].CGColor;
    shadow.layer.shadowRadius = 2.0f;
    shadow.layer.shadowOffset = CGSizeMake(1,1);
    shadow.layer.shadowOpacity = 0.5f;
    
    UILabel* buttonText = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _getStartedButton.frame.size.width, _getStartedButton.frame.size.height)];
    buttonText.center = CGPointMake(_getStartedButton.frame.size.width/2, _getStartedButton.frame.size.height/2);
    buttonText.font = [UIFont fontWithName:@"where stars shine the brightest" size:45.0f];
    buttonText.text = @"Get started!";
    buttonText.textColor = [UIColor whiteColor];
    buttonText.textAlignment = UITextAlignmentCenter;
    buttonText.backgroundColor = [UIColor clearColor];
    
    FlexibleGradientView* whiteGradientOverlay = [[FlexibleGradientView alloc] initWithFrame:buttonText.frame andViewToPassthroughTo:_getStartedButton];
    whiteGradientOverlay.alpha = 0.4;
    whiteGradientOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [(CAGradientLayer*)[whiteGradientOverlay layer] setColors:[NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[[UIColor clearColor] CGColor], nil]];
    
    _getStartedButtonDepressedOverlay = [[FlexibleGradientView alloc] initWithFrame:buttonText.frame andViewToPassthroughTo:_getStartedButton];
    _getStartedButtonDepressedOverlay.alpha = 0.6;
    _getStartedButtonDepressedOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [(CAGradientLayer*)[_getStartedButtonDepressedOverlay layer] setColors:[NSArray arrayWithObjects:(id)[[UIColor blackColor] CGColor], (id)[[UIColor clearColor] CGColor], nil]];
    _getStartedButtonDepressedOverlay.hidden = YES;
    
    [_getStartedButton addSubview:buttonText];
    [_getStartedButton addSubview:whiteGradientOverlay];
    [_getStartedButton addSubview:_getStartedButtonDepressedOverlay];
    
    [_foregroundScrollView addSubview:shadow];
    [_foregroundScrollView addSubview:_getStartedButton];
}


#pragma UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    CGFloat pageWidth = _foregroundScrollView.frame.size.width;
    int page = floor((_foregroundScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    [_pageControl setCurrentPage:page];
    
    CGFloat offsetX = _foregroundScrollView.contentOffset.x;
    CGFloat backgroundTargetOffsetX = offsetX / kForegroundToBackgroundScrollFactor;
    
    _backgroundScrollView.contentOffset = CGPointMake(backgroundTargetOffsetX, _backgroundScrollView.contentOffset.y);

    // set opacity of the gradient view
    CGFloat newOpacity = 0.9f - (0.45*_foregroundScrollView.contentOffset.x / _foregroundScrollView.contentSize.width);
    _smoothGradient.alpha = newOpacity;
}

- (void)getStarted:(UIButton*)button
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        _getStartedButtonDepressedOverlay.hidden = YES;
    });
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:kCurrentIntroVersion] forKey:kIntroVersionFinished];
    [self.delegate introCompleted:self];
}

- (void)buttonDown:(UIButton*)button
{
    _getStartedButtonDepressedOverlay.hidden = NO;
}

- (void)buttonCancel:(UIButton*)button
{
    _getStartedButtonDepressedOverlay.hidden = YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"Signup"]) {
        
    }
}
-(NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}
+(BOOL)alreadyCompleted
{
    NSNumber* val = [[NSUserDefaults standardUserDefaults] objectForKey:kIntroVersionFinished];
    return val.intValue >= kCurrentIntroVersion;
}

@end
