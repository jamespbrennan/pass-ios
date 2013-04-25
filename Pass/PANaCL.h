//
//  PANaCL.h
//  Pass
//
//  Created by James Brennan on 2013-04-06.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "sodium.h"
#import "MF_Base64Additions.h"

@interface PANaCL : NSObject
@property (unsafe_unretained, nonatomic) NSString *privateKey;
@property (unsafe_unretained, nonatomic) NSString *publicKey;

- (id)init;
- (id)initWithPrivateKey: (NSString *)privateKey;
- (NSString *)signature:(NSString*)token;
- (NSString *)encodeHex:(NSData *)data;
- (NSData *)decodeHex:(NSString *)data;

@end