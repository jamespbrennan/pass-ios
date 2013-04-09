//
//  JBRSA.h
//  Pass
//
//  Created by James Brennan on 2013-04-06.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <openssl/rsa.h>
#include <openssl/engine.h>
#include <openssl/pem.h>

@interface JBRSA : NSObject
@property (unsafe_unretained, nonatomic) RSA *rsa;

- (id)init;
- (id)initWithPrivateKey: (NSString *)privateKey;
- (void)loadPrivateKey:(NSString*) key;
- (NSString *)privateEncrypt:(NSString*)plaintext;

@end