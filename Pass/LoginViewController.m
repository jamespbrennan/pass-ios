//
//  LoginViewController.m
//  Pass
//
//  Created by James Brennan on 2013-03-27.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) alertStatus:(NSString *)msg :(NSString *)title
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    
    [alertView show];
}

- (IBAction) loginClicked:(id)sender {
    Pass *pass = [Pass sharedInstance];
    NSError *error = [[NSError alloc] init];
    
    if ([pass login:[_txtEmail text] password:[_txtPassword text] error:&error])
    {
        // Change the view to logged in
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate loggedIn];
    }
    else
    {
        // Display an error message
        [self errorMessage:error];
    }
}

- (IBAction) createAccountClicked:(id)sender {
    Pass *pass = [Pass sharedInstance];
    NSError *error = [[NSError alloc] init];
    
    if( [pass registerUser:[_txtEmail text] password:[_txtPassword text] error:&error] )
    {
        if( [pass login:[_txtEmail text] password:[_txtPassword text] error:&error] )
        {
            // Change the view to logged in
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate loggedIn];
        }
        else
        {
            // Display an error message
            [self errorMessage:error];
        }
    }
    else
    {
        // Display an error message
        [self errorMessage:error];
    }
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

- (IBAction) backgroundClicked:(id)sender {
    [_txtEmail resignFirstResponder];
    [_txtPassword resignFirstResponder];
}

@end
