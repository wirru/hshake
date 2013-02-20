//
//  ViewController.m
//  VideoPlayRecord
//
//  Created by Abdul Azeem Khan on 5/9/12.
//  Copyright (c) 2012 DataInvent. All rights reserved.
//

#import "ViewController.h"
#import "IntroductionViewController.h"

@implementation ViewController

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
    
    UIButton* newShakeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    newShakeButton.backgroundColor = [UIColor colorWithRed:33.0f/255.0f green:136.0f/255.0f blue:233.0f/255.0f alpha:1.0f];
    newShakeButton.frame = CGRectMake(0, 0, 280, 50);
    newShakeButton.center = CGPointMake(self.view.bounds.size.width/2, self.view.frame.size.height/2);
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
