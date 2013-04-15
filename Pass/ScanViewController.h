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
#import "AppDelegate.h"
#import "Pass.h"


@class AppDelegate;

@interface ScanViewController : UIViewController <ZXCaptureDelegate, UINavigationControllerDelegate>

@property (nonatomic, retain) ZXCapture* capture;

- (id) processResult:(ZXResult*)result;
- (void) alertStatus:(NSString *)msg :(NSString *)title;

@end
