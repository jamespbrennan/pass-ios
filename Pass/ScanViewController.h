//
//  ScanViewController.h
//  Pass
//
//  Created by James Brennan on 2013-04-03.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "ZXingObjC.h"
#import "IIViewDeckController.h"
#import "KeychainItemWrapper.h"
#import "JBRSA.h"
#include "AppDelegate.h"
#import "FMDatabase.h"

@class AppDelegate;

@interface ScanViewController : UIViewController <ZXCaptureDelegate, UINavigationControllerDelegate>

@property (nonatomic, retain) ZXCapture* capture;
@property (unsafe_unretained, nonatomic) IBOutlet UIBarButtonItem *btnShowNavigation;

- (IBAction)showNavigationClicked;
- (bool)register:(NSString*)token serviceId:(int)serviceId sessionId:(int)sessionId;
- (bool)authenticate:(NSString*)token serviceId:(int)serviceId sessionId:(int)sessionId keyName:(NSString*)keyName;
- (void) alertStatus:(NSString *)msg :(NSString *)title;

@end
