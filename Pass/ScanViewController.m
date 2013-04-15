//
//  ScanViewController.m
//  Pass
//
//  Created by James Brennan on 2013-04-03.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import "ScanViewController.h"

@interface ScanViewController ()

@end

@implementation ScanViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Pass";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Left" style:UIBarButtonItemStyleBordered target:self.viewDeckController action:@selector(toggleLeftView)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.capture = [[ZXCapture alloc] init];
    self.capture.delegate = self;
    self.capture.rotation = 90.0f;
    
    // Use the back camera
    self.capture.camera = self.capture.back;
    
    self.capture.layer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.capture.layer];
}

- (void)captureResult:(ZXCapture*)capture result:(ZXResult*)result {
    if (result) {
        [self performSelectorOnMainThread:@selector(setText:) withObject:[self processResult:result] waitUntilDone:YES];
    }
}

- (id)processResult:(ZXResult*)result {
    // Vibrate
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    NSArray *chunks = [result.text componentsSeparatedByString: @":"];
    Pass *pass = [Pass sharedInstance];
    
    if(chunks.count < 3)
    {
        // Extract values from QR code
        int sessionId = [chunks[0] intValue];
        int serviceId = [chunks[1] intValue];
        NSString *token = chunks[2];
        
        if([pass getServicePrivateKey:serviceId] == nil)
        {
            // Register first, then authenticate
            if( ! [pass register:serviceId] )
            {
                [self alertStatus:@"Sorry, I wasn't able to register you succesfully. Please try logging in again." :@""];
            }
        }
        
        // Authenticate
        if ( ! [pass authenticate:token sessionId:sessionId serviceId:serviceId] )
        {
            [self alertStatus:@"Sorry, I wasn't able to log you in successfully." :@""];
        }
    }
    else
    {
        [self alertStatus:@"Sorry, that was not a valid login code. Please try loggin in again. Please try logging in again." :@""];
    }
    
    return self;
}

- (void) alertStatus:(NSString *)message :(NSString *)title
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    
    [alertView show];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}
@end
