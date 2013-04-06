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
@property (strong, nonatomic) UIViewController *loginViewController;
@property (strong, nonatomic) UIViewController *scanViewController;
@property (strong, nonatomic) UIViewController *navigationViewController;

@property (strong, nonatomic) NSString *token;

@end
