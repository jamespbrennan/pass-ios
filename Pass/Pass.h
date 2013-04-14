//
//  Pass.h
//  Pass
//
//  Created by James Brennan on 2013-04-12.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/sysctl.h>
#import "FMDatabase.h"
#import "KeychainItemWrapper.h"
#import "SBJson.h"
#import "JBRSA.h"

@interface Pass : NSObject
@property(nonatomic,strong) FMDatabase *db;

+ (id)sharedInstance;
@end
