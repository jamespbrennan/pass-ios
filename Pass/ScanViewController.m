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

// Capture Result
//
//
//

- (void)captureResult:(ZXCapture*)capture result:(ZXResult*)result {
    if (result && ! [result.text isEqualToString:self.lastCapture]) {
        // Store the result so we don't continually run the same QR again and again
        self.lastCapture = result.text;
        // Clear the result out in 10s
        [self performSelector:@selector(resetLastCapture:) withObject:self afterDelay:10.0];
        
        [self processResult:result];
    }
}

// Process Result
//
//
//

- (id)processResult:(ZXResult*)result {
    // Vibrate
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    NSArray *chunks = [result.text componentsSeparatedByString: @":"];
    Pass *pass = [Pass sharedInstance];
    NSError *error = [[NSError alloc] init];
    
    if(chunks.count == 3)
    {
        // Extract values from QR code
        int sessionId = [chunks[0] intValue];
        int serviceId = [chunks[1] intValue];
        NSString *token = chunks[2];
        
        if([[pass getServicePrivateKey:serviceId] isEqualToString:@""] || [pass getServicePrivateKey:serviceId] == nil)
        {
            NSLog(@"Registering...");
            
            // Register first, then authenticate
            if( ! [pass registerWithService:serviceId error:&error] )
            {
                [self errorMessage:error];
                return self;
            }
        }
        
        // Authenticate
        if ( ! [pass authenticate:token sessionId:sessionId serviceId:serviceId error:&error] )
        {
            [self errorMessage:error];
        }
    }
    else
    {
        [self alertStatus:@"Sorry, that was not a valid login code. Please try loggin in again. Please try logging in again." :@"Hey there!"];
    }
    
    return self;
}

// Alert Status
//
//
//

- (void) alertStatus:(NSString *)message :(NSString *)title
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    
    [alertView show];
}

// Error Message
//
// Display an error message from an NSError.
//

- (void) errorMessage:(NSError*)error
{
    NSString *message = (error) ? [[NSString alloc] initWithFormat:@"%@", error.localizedDescription] : [[NSString alloc] initWithFormat:@"Sorry, something has gone wrong."];
    [self alertStatus:message :@"Hey there!"];
}

// Reset last capture
//
//
//

- (void) resetLastCapture:(id)s
{
    self.lastCapture = nil;
}

- (void)viewDidUnload {
    [super viewDidUnload];
}
@end
