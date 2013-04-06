//
//  ScanViewController.h
//  Pass
//
//  Created by James Brennan on 2013-04-03.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZXingObjC.h"

@interface ScanViewController : UIViewController <ZXCaptureDelegate, UINavigationControllerDelegate>

@property (nonatomic, retain) ZXCapture* capture;

@end
