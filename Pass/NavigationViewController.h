//
//  NavigationViewController.h
//  Pass
//
//  Created by James Brennan on 2013-04-03.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface NavigationViewController : UITableViewController
{
NSMutableArray *_displayedObjects;
}

@property (nonatomic, retain) NSMutableArray *displayedObjects;
@end
