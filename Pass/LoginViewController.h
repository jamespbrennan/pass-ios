//
//  LoginViewController.h
//  Pass
//
//  Created by James Brennan on 2013-03-27.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBJson.h"
#import "KeychainItemWrapper.h"

@interface LoginViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *txtEmail;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;

- (IBAction)loginClicked:(id)sender;
- (IBAction)createAccountClicked:(id)sender;
- (IBAction)backgroundClicked:(id)sender;

- (void)doLogin:(NSString*)email withPassword:(NSString*)password;
- (void)doRegistration:(NSString*)email withPassword:(NSString*)password;

- (NSMutableURLRequest*)prepareLoginRequest:(NSString*)email withPassword:(NSString*)password;
- (NSMutableURLRequest*)prepareRegistrationRequest:(NSString*)email withPassword:(NSString*)password;
- (NSMutableURLRequest*)prepareRequest:(NSString*)email withPassword:(NSString*)password;

- (void)storeToken:(NSString*)token;

@end
