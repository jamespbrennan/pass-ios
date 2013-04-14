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
@property (unsafe_unretained, nonatomic) NSString *privateKey;
@property (unsafe_unretained, nonatomic) NSString *publicKey;

- (id)init;
- (id)initWithPrivateKey: (NSString *)privateKey;
- (id)initWithPrivateKeyAndPublicKey: (NSString *)privateKey publicKey:(NSString*) publicKey;
- (void)loadPublicKey:(NSString*) key;
- (void)loadPrivateKey:(NSString*) key;
- (NSString *)publicEncrypt:(NSString*)plaintext;
- (NSString *)privateEncrypt:(NSString*)plaintext;
- (NSString *)base64EncodePublicEncrypt:(NSString*)plaintext;
- (NSString *)base64EncodePrivateEncrypt:(NSString*)plaintext;
- (NSString *)base64FromString:(NSString *)string encodeWithNewlines:(BOOL)encodeWithNewlines;

@end