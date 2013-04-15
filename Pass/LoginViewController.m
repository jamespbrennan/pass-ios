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
    [pass login:[_txtEmail text] password:[_txtPassword text]];
}

- (IBAction) createAccountClicked:(id)sender {
    Pass *pass = [Pass sharedInstance];
    [pass registerUser:[_txtEmail text] withPassword:[_txtPassword text]];
}

- (IBAction) backgroundClicked:(id)sender {
    [_txtEmail resignFirstResponder];
    [_txtPassword resignFirstResponder];
}

@end
