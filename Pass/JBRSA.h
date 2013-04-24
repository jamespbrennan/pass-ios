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
#include <openssl/sha.h>
#include <openssl/evp.h>
#include <openssl/err.h>
#include <openssl/ssl.h>

@interface JBRSA : NSObject
@property (unsafe_unretained, nonatomic) RSA *rsa;
@property (unsafe_unretained, nonatomic) NSString *privateKey;
@property (unsafe_unretained, nonatomic) NSString *publicKey;

- (id)init;
- (id)initWithPrivateKey: (NSString *)privateKey;
- (void)loadPrivateKey:(NSString*) key;
- (NSString *)signature:(NSString*)token;
- (NSString *)base64EncodeSignature:(NSString*)token;
- (NSString *)base64FromString:(NSString *)string encodeWithNewlines:(BOOL)encodeWithNewlines;
- (NSString *)sha512FromString:(NSString *)string;
- (NSString *)privateEncrypt:(NSString*)plaintext;

@end