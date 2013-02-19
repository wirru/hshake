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
    
    BOOL first;
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
    
    UIButton* record = [UIButton buttonWithType:UIButtonTypeCustom];
    record.backgroundColor = [UIColor colorWithRed:33.0f/255.0f green:136.0f/255.0f blue:233.0f/255.0f alpha:1.0f];
    record.frame = CGRectMake(0, 0, 280, 50);
    record.center = CGPointMake(self.view.bounds.size.width/2, _foregroundScrollView.frame.size.height/2);
    [record addTarget:self action:@selector(recordFirst:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel* buttonText1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, record.frame.size.width, record.frame.size.height)];
    buttonText1.center = CGPointMake(record.frame.size.width/2, record.frame.size.height/2);
    buttonText1.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:45.0f];
    buttonText1.text = @"Record First";
    buttonText1.textColor = [UIColor whiteColor];
    buttonText1.textAlignment = UITextAlignmentCenter;
    buttonText1.backgroundColor = [UIColor clearColor];
    [record addSubview:buttonText1];
    [_foregroundScrollView addSubview:record];
    
    
    // Setup the second page

    UIButton* record2 = [UIButton buttonWithType:UIButtonTypeCustom];
    record2.backgroundColor = [UIColor colorWithRed:33.0f/255.0f green:136.0f/255.0f blue:233.0f/255.0f alpha:1.0f];
    record2.frame = CGRectMake(0, 0, 280, 50);
    record2.center = CGPointMake(self.view.bounds.size.width*(1)+self.view.bounds.size.width/2, _foregroundScrollView.frame.size.height/2);
    [record2 addTarget:self action:@selector(recordSecond:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel* buttonText2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, record2.frame.size.width, record2.frame.size.height)];
    buttonText2.center = CGPointMake(record2.frame.size.width/2, record2.frame.size.height/2);
    buttonText2.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:45.0f];
    buttonText2.text = @"Record Second";
    buttonText2.textColor = [UIColor whiteColor];
    buttonText2.textAlignment = UITextAlignmentCenter;
    buttonText2.backgroundColor = [UIColor clearColor];
    [record2 addSubview:buttonText2];
    [_foregroundScrollView addSubview:record2];
        
    // Setup the third page
    UIButton* merge = [UIButton buttonWithType:UIButtonTypeCustom];
    merge.backgroundColor = [UIColor colorWithRed:33.0f/255.0f green:136.0f/255.0f blue:233.0f/255.0f alpha:1.0f];
    merge.frame = CGRectMake(0, 0, 280, 50);
    merge.center = CGPointMake(self.view.bounds.size.width*(2)+self.view.bounds.size.width/2, _foregroundScrollView.frame.size.height/2);
    [merge addTarget:self action:@selector(mergeAndSave:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel* buttonText3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, merge.frame.size.width, merge.frame.size.height)];
    buttonText3.center = CGPointMake(merge.frame.size.width/2, merge.frame.size.height/2);
    buttonText3.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:45.0f];
    buttonText3.text = @"Get Shakin!";
    buttonText3.textColor = [UIColor whiteColor];
    buttonText3.textAlignment = UITextAlignmentCenter;
    buttonText3.backgroundColor = [UIColor clearColor];
    [merge addSubview:buttonText3];
    [_foregroundScrollView addSubview:merge];
    
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
            firstVideoPath = moviePath;
        }
        else {
            secondVideoPath = moviePath;
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
    firstAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:firstVideoPath] options:nil];
    secondAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:secondVideoPath] options:nil];
    
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
        AVAssetTrack *FirstAssetTrack = [[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        UIImageOrientation FirstAssetOrientation_  = UIImageOrientationUp;
        BOOL  isFirstAssetPortrait_  = NO;
        CGAffineTransform firstTransform = FirstAssetTrack.preferredTransform;
        if(firstTransform.a == 0 && firstTransform.b == 1.0 && firstTransform.c == -1.0 && firstTransform.d == 0)  {FirstAssetOrientation_= UIImageOrientationRight; isFirstAssetPortrait_ = YES;}
        if(firstTransform.a == 0 && firstTransform.b == -1.0 && firstTransform.c == 1.0 && firstTransform.d == 0)  {FirstAssetOrientation_ =  UIImageOrientationLeft; isFirstAssetPortrait_ = YES;}
        if(firstTransform.a == 1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == 1.0)   {FirstAssetOrientation_ =  UIImageOrientationUp;}
        if(firstTransform.a == -1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == -1.0) {FirstAssetOrientation_ = UIImageOrientationDown;}
        CGFloat FirstAssetScaleToFitRatio = 320.0/FirstAssetTrack.naturalSize.width;
        if(isFirstAssetPortrait_){
            FirstAssetScaleToFitRatio = 320.0/FirstAssetTrack.naturalSize.height;
            CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
            [FirstlayerInstruction setTransform:CGAffineTransformConcat(FirstAssetTrack.preferredTransform, FirstAssetScaleFactor) atTime:kCMTimeZero];
        }else{
            CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
            [FirstlayerInstruction setTransform:CGAffineTransformConcat(CGAffineTransformConcat(FirstAssetTrack.preferredTransform, FirstAssetScaleFactor),CGAffineTransformMakeTranslation(0, 160)) atTime:kCMTimeZero];
        }
        [FirstlayerInstruction setOpacity:0.0 atTime:firstAsset.duration];
        
        AVMutableVideoCompositionLayerInstruction *SecondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:secondTrack];
        AVAssetTrack *SecondAssetTrack = [[secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        UIImageOrientation SecondAssetOrientation_  = UIImageOrientationUp;
        BOOL  isSecondAssetPortrait_  = NO;
        CGAffineTransform secondTransform = SecondAssetTrack.preferredTransform;
        if(secondTransform.a == 0 && secondTransform.b == 1.0 && secondTransform.c == -1.0 && secondTransform.d == 0)  {SecondAssetOrientation_= UIImageOrientationRight; isSecondAssetPortrait_ = YES;}
        if(secondTransform.a == 0 && secondTransform.b == -1.0 && secondTransform.c == 1.0 && secondTransform.d == 0)  {SecondAssetOrientation_ =  UIImageOrientationLeft; isSecondAssetPortrait_ = YES;}
        if(secondTransform.a == 1.0 && secondTransform.b == 0 && secondTransform.c == 0 && secondTransform.d == 1.0)   {SecondAssetOrientation_ =  UIImageOrientationUp;}
        if(secondTransform.a == -1.0 && secondTransform.b == 0 && secondTransform.c == 0 && secondTransform.d == -1.0) {SecondAssetOrientation_ = UIImageOrientationDown;}
        CGFloat SecondAssetScaleToFitRatio = 320.0/SecondAssetTrack.naturalSize.width;
        if(isSecondAssetPortrait_){
            SecondAssetScaleToFitRatio = 320.0/SecondAssetTrack.naturalSize.height;
            CGAffineTransform SecondAssetScaleFactor = CGAffineTransformMakeScale(SecondAssetScaleToFitRatio,SecondAssetScaleToFitRatio);
            [SecondlayerInstruction setTransform:CGAffineTransformConcat(SecondAssetTrack.preferredTransform, SecondAssetScaleFactor) atTime:firstAsset.duration];
        }else{
            ;
            CGAffineTransform SecondAssetScaleFactor = CGAffineTransformMakeScale(SecondAssetScaleToFitRatio,SecondAssetScaleToFitRatio);
            [SecondlayerInstruction setTransform:CGAffineTransformConcat(CGAffineTransformConcat(SecondAssetTrack.preferredTransform, SecondAssetScaleFactor),CGAffineTransformMakeTranslation(0, 160)) atTime:firstAsset.duration];
        }
        
        
        MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,SecondlayerInstruction,nil];;
        
        AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
        MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
        MainCompositionInst.frameDuration = CMTimeMake(1, 30);
        MainCompositionInst.renderSize = CGSizeMake(320.0, 480.0);
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"mergeVideo-%d.mov",arc4random() % 1000]];
        
        NSURL *url = [NSURL fileURLWithPath:myPathDocs];
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
        exporter.outputURL=url;
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        exporter.videoComposition = MainCompositionInst;
        exporter.shouldOptimizeForNetworkUse = YES;
        [exporter exportAsynchronouslyWithCompletionHandler:^
         {
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self exportDidFinish:exporter];
             });
         }];
    }
}
- (void)exportDidFinish:(AVAssetExportSession*)session
{
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
                                                }
                                                
                                            });
                                            
                                        }];
        }
    }
	
    //audioAsset = nil;
    firstVideoPath = nil;
    secondVideoPath = nil;
    firstAsset = nil;
    secondAsset = nil;
    //[ActivityView stopAnimating];
}

@end
