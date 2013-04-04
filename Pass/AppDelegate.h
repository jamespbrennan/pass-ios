//
//  AppDelegate.h
//  Pass
//
//  Created by James Brennan on 2013-03-27.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LoginViewController;
@class ScanViewController;
@class NavigationViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) LoginViewController *loginViewController;
@property (strong, nonatomic) ScanViewController *scanViewController;
@property (strong, nonatomic) NavigationViewController *navigationViewController;

@property (strong, nonatomic) NSString *token;

@end
