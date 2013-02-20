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

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#define kCurrentIntroVersion 1
#define kIntroVersionFinished @"IntroVersionAlreadyFinished"
#define CORNER_RADIUS 7.0f
#define kNumberOfIntroPages 3
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
    
    NSString* firstVideoPath;
    NSString* secondVideoPath;
    
    AVURLAsset* firstAsset;
    AVURLAsset* secondAsset;
    AVURLAsset* finalAsset;
    
    AVAssetExportSession *exporter;
    
    UIImageView* firstVideoPreview;
    UIImageView* secondVideoPreview;
    UIImageView* finalVideoPreview;
    
    BOOL first;
    
    UIButton *recordFirstButton;
    UIButton *recordSecondButton;
    UIButton *mergeButton;
    UIButton *saveButton;
}

@end

@implementation IntroductionViewController

- (id)init
{
    self = [super init];
    if (self) {
        first = YES;
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
    
    
    UILabel *firstTitle = [UILabel new];
    firstTitle.frame = CGRectMake(0, 30, 320, 70);
    firstTitle.text = @"ACT 1";
    firstTitle.font = [UIFont fontWithName:@"Dirty Ego" size:65.0f];
    firstTitle.textColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1];
    firstTitle.backgroundColor = [UIColor clearColor];
    firstTitle.textAlignment = NSTextAlignmentCenter;
    [_foregroundScrollView addSubview:firstTitle];
    
    UILabel *firstLabel = [UILabel new];
    firstLabel.frame = CGRectMake(0, 100, 320, 40);
    firstLabel.text = @"Record your first half";
    firstLabel.font = [UIFont fontWithName:@"Dirty Ego" size:32.0f];
    firstLabel.textColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1];
    firstLabel.backgroundColor = [UIColor clearColor];
    firstLabel.textAlignment = NSTextAlignmentCenter;
    [_foregroundScrollView addSubview:firstLabel];
    
    firstVideoPreview = [[UIImageView alloc] init];
    firstVideoPreview.frame = CGRectMake(0, 0, 320, 180);
    firstVideoPreview.center = CGPointMake(self.view.bounds.size.width/2, 200);
    firstVideoPreview.contentMode = UIViewContentModeScaleAspectFill;
    firstVideoPreview.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapFirstVideoGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playFirstMovie)];
    [firstVideoPreview addGestureRecognizer:tapFirstVideoGesture];
    
    [_foregroundScrollView addSubview:firstVideoPreview];
    
    
    recordFirstButton = [UIButton buttonWithType:UIButtonTypeCustom];
    recordFirstButton.backgroundColor = [UIColor colorWithRed:33.0f/255.0f green:136.0f/255.0f blue:233.0f/255.0f alpha:1.0f];
    recordFirstButton.frame = CGRectMake(0, 0, 280, 50);
    recordFirstButton.center = CGPointMake(self.view.bounds.size.width/2, _foregroundScrollView.frame.size.height/2);
    [recordFirstButton addTarget:self action:@selector(recordFirst:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel* buttonText1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, recordFirstButton.frame.size.width, recordFirstButton.frame.size.height)];
    buttonText1.center = CGPointMake(recordFirstButton.frame.size.width/2, recordFirstButton.frame.size.height/2);
    buttonText1.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25.0f];
    buttonText1.text = @"Record First";
    buttonText1.textColor = [UIColor whiteColor];
    buttonText1.textAlignment = UITextAlignmentCenter;
    buttonText1.backgroundColor = [UIColor clearColor];
    [recordFirstButton addSubview:buttonText1];
    [_foregroundScrollView addSubview:recordFirstButton];
    
    
    // Setup the second page
    
    UILabel *secondTitle = [UILabel new];
    secondTitle.frame = CGRectMake(320, 30, 320, 70);
    secondTitle.text = @"ACT 2";
    secondTitle.font = [UIFont fontWithName:@"Dirty Ego" size:65.0f];
    secondTitle.textColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1];
    secondTitle.backgroundColor = [UIColor clearColor];
    secondTitle.textAlignment = NSTextAlignmentCenter;
    [_foregroundScrollView addSubview:secondTitle];

    
    UILabel *secondLabel = [UILabel new];
    secondLabel.frame = CGRectMake(320, 100, 320, 40);
    secondLabel.text = @"Record your second half";
    secondLabel.font = [UIFont fontWithName:@"Dirty Ego" size:32.0f];
    secondLabel.textColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1];
    secondLabel.backgroundColor = [UIColor clearColor];
    secondLabel.textAlignment = NSTextAlignmentCenter;
    [_foregroundScrollView addSubview:secondLabel];
    
    secondVideoPreview = [[UIImageView alloc] init];
    secondVideoPreview.frame = CGRectMake(0, 0, 320, 180);
    secondVideoPreview.center = CGPointMake(self.view.bounds.size.width*(1)+self.view.bounds.size.width/2, 200);
    secondVideoPreview.contentMode = UIViewContentModeScaleAspectFill;
    secondVideoPreview.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapSecondVideoGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playSecondMovie)];
    [secondVideoPreview addGestureRecognizer:tapSecondVideoGesture];
    [_foregroundScrollView addSubview:secondVideoPreview];
    
    recordSecondButton = [UIButton buttonWithType:UIButtonTypeCustom];
    recordSecondButton.backgroundColor = [UIColor colorWithRed:33.0f/255.0f green:136.0f/255.0f blue:233.0f/255.0f alpha:1.0f];
    recordSecondButton.frame = CGRectMake(0, 0, 280, 50);
    recordSecondButton.center = CGPointMake(self.view.bounds.size.width*(1)+self.view.bounds.size.width/2, _foregroundScrollView.frame.size.height/2);
    [recordSecondButton addTarget:self action:@selector(recordSecond:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel* buttonText2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, recordSecondButton.frame.size.width, recordSecondButton.frame.size.height)];
    buttonText2.center = CGPointMake(recordSecondButton.frame.size.width/2, recordSecondButton.frame.size.height/2);
    buttonText2.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25.0f];
    buttonText2.text = @"Record Second";
    buttonText2.textColor = [UIColor whiteColor];
    buttonText2.textAlignment = UITextAlignmentCenter;
    buttonText2.backgroundColor = [UIColor clearColor];
    [recordSecondButton addSubview:buttonText2];
    [_foregroundScrollView addSubview:recordSecondButton];
    
        
    // Setup the third page
    UILabel *finalTitle = [UILabel new];
    finalTitle.frame = CGRectMake(640, 30, 320, 70);
    finalTitle.text = @"Epilogue";
    finalTitle.font = [UIFont fontWithName:@"Dirty Ego" size:65.0f];
    finalTitle.textColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1];
    finalTitle.backgroundColor = [UIColor clearColor];
    finalTitle.textAlignment = NSTextAlignmentCenter;
    [_foregroundScrollView addSubview:finalTitle];
    
    
    UILabel *finalLabel = [UILabel new];
    finalLabel.frame = CGRectMake(640, 100, 320, 40);
    finalLabel.text = @"Shake it up";
    finalLabel.font = [UIFont fontWithName:@"Dirty Ego" size:32.0f];
    finalLabel.textColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1];
    finalLabel.backgroundColor = [UIColor clearColor];
    finalLabel.textAlignment = NSTextAlignmentCenter;
    [_foregroundScrollView addSubview:finalLabel];
    
    finalVideoPreview = [[UIImageView alloc] init];
    finalVideoPreview.frame = CGRectMake(0, 0, 320, 180);
    finalVideoPreview.center = CGPointMake(self.view.bounds.size.width*(2)+self.view.bounds.size.width/2, 200);
    finalVideoPreview.contentMode = UIViewContentModeScaleAspectFill;
    finalVideoPreview.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapFinalVideoGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playFinalMovie)];
    [finalVideoPreview addGestureRecognizer:tapFinalVideoGesture];
    [_foregroundScrollView addSubview:finalVideoPreview];
    
    mergeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    mergeButton.backgroundColor = [UIColor colorWithRed:33.0f/255.0f green:136.0f/255.0f blue:233.0f/255.0f alpha:1.0f];
    mergeButton.frame = CGRectMake(0, 0, 280, 50);
    mergeButton.center = CGPointMake(self.view.bounds.size.width*(2)+self.view.bounds.size.width/2, _foregroundScrollView.frame.size.height/2);
    [mergeButton addTarget:self action:@selector(mergeAndSave:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel* buttonText3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, mergeButton.frame.size.width, mergeButton.frame.size.height)];
    buttonText3.center = CGPointMake(mergeButton.frame.size.width/2, mergeButton.frame.size.height/2);
    buttonText3.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25.0f];
    buttonText3.text = @"Get Shakin!";
    buttonText3.textColor = [UIColor whiteColor];
    buttonText3.textAlignment = UITextAlignmentCenter;
    buttonText3.backgroundColor = [UIColor clearColor];
    [mergeButton addSubview:buttonText3];
    [_foregroundScrollView addSubview:mergeButton];
    
    
    saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    saveButton.backgroundColor = [UIColor colorWithRed:33.0f/255.0f green:136.0f/255.0f blue:233.0f/255.0f alpha:1.0f];
    saveButton.frame = CGRectMake(0, 0, 280, 50);
    saveButton.center = CGPointMake(self.view.bounds.size.width*(2)+self.view.bounds.size.width/2, _foregroundScrollView.frame.size.height/2 + 60);
    [saveButton addTarget:self action:@selector(exportDidFinish:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel* saveButtonText = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, saveButton.frame.size.width, saveButton.frame.size.height)];
    saveButtonText.center = CGPointMake(saveButton.frame.size.width/2, saveButton.frame.size.height/2);
    saveButtonText.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25.0f];
    saveButtonText.text = @"Save to camera roll";
    saveButtonText.textColor = [UIColor whiteColor];
    saveButtonText.textAlignment = UITextAlignmentCenter;
    saveButtonText.backgroundColor = [UIColor clearColor];
    [saveButton addSubview:saveButtonText];
    [_foregroundScrollView addSubview:saveButton];
    saveButton.hidden = YES;
    
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

- (void)recordFirst:(UIButton*)button {
    first = YES;
    [self startCameraControllerFromViewController:self usingDelegate:self];
}

- (void)recordSecond:(UIButton*)button {
    first = NO;
    [self startCameraControllerFromViewController:self usingDelegate:self];
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



- (BOOL) startCameraControllerFromViewController: (UIViewController*) controller
                                   usingDelegate: (id <UIImagePickerControllerDelegate,
                                                   UINavigationControllerDelegate>) delegate {
    
    if (([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera] == NO)
        || (delegate == nil)
        || (controller == nil))
        return NO;
    
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    // Displays a control that allows the user to choose movie capture
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    cameraUI.allowsEditing = NO;
    cameraUI.videoMaximumDuration = 15.0f;
    
    
    cameraUI.delegate = delegate;
    
    [controller presentModalViewController: cameraUI animated: YES];
    return YES;
}


// For responding to the user accepting a newly-captured picture or movie
- (void) imagePickerController: (UIImagePickerController *) picker
 didFinishPickingMediaWithInfo: (NSDictionary *) info {
    
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    [self dismissModalViewControllerAnimated:NO];
    
    // Handle a movie capture
    if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0)
        == kCFCompareEqualTo) {
        
        NSString *moviePath = [[info objectForKey:
                                UIImagePickerControllerMediaURL] path];
        if(first) {
            firstAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:moviePath] options:nil];
            AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:firstAsset];
            gen.appliesPreferredTrackTransform = YES;
            CMTime time = CMTimeMakeWithSeconds(0.0, 600);
            NSError *error = nil;
            CMTime actualTime;
            
            CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
            UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
            CGImageRelease(image);
            
            firstVideoPreview.image = thumb;
        }
        else {
            secondAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:moviePath] options:nil];
            AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:firstAsset];
            gen.appliesPreferredTrackTransform = YES;
            CMTime time = CMTimeMakeWithSeconds(0.0, 600);
            NSError *error = nil;
            CMTime actualTime;
            
            CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
            UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
            CGImageRelease(image);
            
            secondVideoPreview.image = thumb;
        }
        
        CGPoint offset = _foregroundScrollView.contentOffset;
        offset.x += _foregroundScrollView.bounds.size.width;
        [_foregroundScrollView setContentOffset:offset animated:YES];
        /*if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (moviePath)) {
            UISaveVideoAtPathToSavedPhotosAlbum (moviePath,self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }*/
        
        
    }
}



- (void) mergeAndSave:(UIButton*)button{
    
    if(firstAsset !=nil && secondAsset!=nil){
        //[ActivityView startAnimating];
        //Create AVMutableComposition Object.This object will hold our multiple AVMutableCompositionTrack.
        AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
        
        //VIDEO TRACK
        AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration) ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
        
        AVMutableCompositionTrack *secondTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondAsset.duration) ofTrack:[[secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:firstAsset.duration error:nil];
        
        //AUDIO TRACK
        NSString *soundFilePath = [[NSBundle mainBundle] pathForResource: @"hshake"
                                                                  ofType: @"mp3"];
        NSURL* songURL = [NSURL fileURLWithPath:soundFilePath];
        AVAsset *audioAsset = [AVAsset assetWithURL:songURL];
        
        if(audioAsset!=nil){
            AVMutableCompositionTrack *AudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            NSArray* test = [audioAsset tracksWithMediaType:AVMediaTypeAudio];
            [AudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeAdd(firstAsset.duration, secondAsset.duration)) ofTrack:[test objectAtIndex:0] atTime:kCMTimeZero error:nil];
        }
        
        AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeAdd(firstAsset.duration, secondAsset.duration));
        
        //FIXING ORIENTATION//
        AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];

        [FirstlayerInstruction setOpacity:0.0 atTime:firstAsset.duration];
        
        AVMutableVideoCompositionLayerInstruction *SecondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:secondTrack];
        
        MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,SecondlayerInstruction,nil];;
        
        AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.renderSize = CGSizeMake(firstAsset.naturalSize.width, firstAsset.naturalSize.height);
        videoComposition.frameDuration = CMTimeMake(1, 30);
        
        AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
        MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
        MainCompositionInst.frameDuration = CMTimeMake(1, 30);
        MainCompositionInst.renderSize = CGSizeMake(firstAsset.naturalSize.width, firstAsset.naturalSize.height);
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"mergeVideo-%d.mov",arc4random() % 1000]];
        
        NSURL *url = [NSURL fileURLWithPath:myPathDocs];
        
        exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
        exporter.outputURL=url;
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        exporter.videoComposition = MainCompositionInst;
        exporter.shouldOptimizeForNetworkUse = YES;
        [exporter exportAsynchronouslyWithCompletionHandler:^
         {
             dispatch_async(dispatch_get_main_queue(), ^{
                 
                 finalAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
                 
                 AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:finalAsset];
                 gen.appliesPreferredTrackTransform = YES;
                 CMTime time = CMTimeMakeWithSeconds(0.0, 600);
                 NSError *error = nil;
                 CMTime actualTime;
                 
                 CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
                 UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
                 CGImageRelease(image);
                 
                 finalVideoPreview.image = thumb;
                 saveButton.hidden = NO;
                 //[self exportDidFinish:exporter];
             });
         }];
    }
}

- (void)exportDidFinish:(UIButton*)button
{
    AVAssetExportSession* session = exporter;
    if(session.status == AVAssetExportSessionStatusCompleted){
        NSURL *outputURL = session.outputURL;
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
            [library writeVideoAtPathToSavedPhotosAlbum:outputURL
                                        completionBlock:^(NSURL *assetURL, NSError *error){
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                if (error) {
                                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil, nil];
                                                    [alert show];
                                                }else{
                                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"  delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
                                                    [alert show];
                                                    
                                                    [self dismissModalViewControllerAnimated:YES];
                                                }
                                                
                                            });
                                            
                                        }];
        }
    }
	
    firstAsset = nil;
    secondAsset = nil;
}

- (void)playFirstMovie {
    if(firstAsset != nil) {
        [self playMovie:firstAsset];
    }
}

- (void)playSecondMovie {
    if(secondAsset != nil) {
        [self playMovie:secondAsset];
    }
}

- (void)playFinalMovie {
    if(finalAsset != nil) {
        [self playMovie:finalAsset];
    }
}

- (void) playMovie:(AVURLAsset*)movieAsset {
    MPMoviePlayerViewController* theMovie =
    [[MPMoviePlayerViewController alloc] initWithContentURL: [movieAsset URL]];
    [self presentMoviePlayerViewControllerAnimated:theMovie];
    
    // Register for the playback finished notification
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector(myMovieFinishedCallback:)
     name: MPMoviePlayerPlaybackDidFinishNotification
     object: theMovie];
    
    
}
// When the movie is done, release the controller.
-(void) myMovieFinishedCallback: (NSNotification*) aNotification
{
    [self dismissMoviePlayerViewControllerAnimated];
    
    MPMoviePlayerController* theMovie = [aNotification object];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver: self
     name: MPMoviePlayerPlaybackDidFinishNotification
     object: theMovie];
    // Release the movie instance created in playMovieAtURL:
}


@end
