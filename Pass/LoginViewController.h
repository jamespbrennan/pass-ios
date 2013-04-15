//
//  LoginViewController.h
//  Pass
//
//  Created by James Brennan on 2013-03-27.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Pass.h"
#import "AppDelegate.h"

@interface LoginViewController : UIViewController
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *txtEmail;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *txtPassword;

- (IBAction)loginClicked:(id)sender;
- (IBAction)createAccountClicked:(id)sender;
- (IBAction)backgroundClicked:(id)sender;

@end
