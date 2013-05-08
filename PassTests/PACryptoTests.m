//
//  PACryptoTests.m
//  Pass
//
//  Created by James Brennan on 2013-05-06.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import "PACryptoTests.h"

@implementation PACryptoTests

//- (id)init;
- (void) testInitCreateKeyPair {
    PACrypto *crypto = [[PACrypto alloc] init];
    
    STAssertTrue([crypto.privateKey length] == 128, @"Private key should be 128 bytes long");
    STAssertTrue([self isHex:crypto.privateKey], @"Private key should be hex");
    STAssertTrue([crypto.publicKey length] == 64, @"Public key should be 64 bytes long");
    STAssertTrue([self isHex:crypto.publicKey], @"Private key should be hex");
}

//- (id)initWithPrivateKey: (NSString *)privateKey;
- (void) testInitWithPrivateKeyStorePrivateKey {
    PACrypto *crypto = [[PACrypto alloc] initWithPrivateKey:@"32ff859efb9b2906d0e1e8142e078aab9bc57f39d3fbe4abbab090934dc93d6ad45063a9248ac67ccb8b9689d3f28da5563f956c7d282ee5bb926e8c4abfbee3"];
    
    STAssertTrue([crypto.privateKey length] == 128, @"Private key should be 64 bytes long");
    STAssertTrue([self isHex:crypto.privateKey], @"Private key should be hex");
}

//- (NSString *)signature:(NSString*)token;
- (void) testSignature {
    PACrypto *crypto = [[PACrypto alloc] init];
    NSString *signature = [crypto signature:@"secret message"];
   
    STAssertTrue([signature length] == 128, @"Signature should be 128 bytes long");
    STAssertTrue([self isHex:signature], @"Signature should be hex");
}

//- (NSString *)encodeHex:(NSData *)data;
- (void) testEncodeHex {
    PACrypto *crypto = [[PACrypto alloc] init];
    NSString *hex = [crypto encodeHex:[[NSString stringWithFormat:@"%@", [NSCharacterSet alphanumericCharacterSet]] dataUsingEncoding:NSUTF8StringEncoding]];
    STAssertTrue([self isHex:hex], @"Encode hex returns a hex string");
}
//- (NSData *)decodeHex:(NSString *)data;
- (void) testEncodeDecodeHex {
    PACrypto *crypto = [[PACrypto alloc] init];
    
    NSString *original = [NSString stringWithFormat:@"%@", [NSCharacterSet alphanumericCharacterSet]];
    NSString *hex = [crypto encodeHex:[original dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *plaintext = [[NSString alloc] initWithData:[crypto decodeHex:hex] encoding:NSUTF8StringEncoding];
    
    STAssertEqualObjects(plaintext, original, @"Decode hex should return original string");
}

- (BOOL) isHex:(NSString*)test
{
    NSCharacterSet *a = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"];
    return ([test rangeOfCharacterFromSet:[a invertedSet]].location == NSNotFound);
}

@end
