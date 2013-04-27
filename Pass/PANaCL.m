//
//  PANaCL.m
//  Pass
//
//  Created by James Brennan on 2013-04-06.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import "PANaCL.h"

@implementation PANaCL

- (id)init {
    
    if (self = [super init])
    {
        NSInteger pkLength = crypto_sign_PUBLICKEYBYTES;
        NSInteger skLength = crypto_sign_SECRETKEYBYTES;
        
        unsigned char pk[pkLength];
        unsigned char sk[skLength];
        
        const unsigned long long buf_len = crypto_sign_SECRETKEYBYTES;
        unsigned char buf[buf_len];
        
        randombytes(buf, buf_len);
        
        int result;
        if( (result = crypto_sign_seed_keypair(pk, sk, buf)) != 0 )
        {
            NSLog(@"crypto_sign_keypair error: %i", result);
        }
        
        self.publicKey = [self encodeHex:[NSData dataWithBytes:pk length:pkLength]];
        self.privateKey = [self encodeHex:[NSData dataWithBytes:sk length:skLength]];
    }
    
    return self;
}

- (id)initWithPrivateKey: (NSString *)privateKey {
    
    if (self = [super init])
    {
        self.privateKey = privateKey;
    }
    
    return self;
}

- (NSString *)signature:(NSString*)token
{
    NSString *signature;
    
    const unsigned char *sk = (const unsigned char *)[[self decodeHex:self.privateKey] bytes];
    const unsigned char *m = (const unsigned char *)[token cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char *sm;
    unsigned long long mlen = strlen((const char*) m);
    unsigned long long smlen;
    
    sm = malloc(mlen + crypto_sign_BYTES);
    
    if( crypto_sign_ed25519(sm, &smlen, m, mlen, sk) != 0 )
    {
        NSLog(@"crypto_sign error");
    }

    // Use only 64 bytes of sm, sm and smlen seem to always end up being 68 bytes which
    // isn't a valid signature. Bug in libsodium?
    signature = [self encodeHex:[NSData dataWithBytes:sm length:64]];
    free(sm);
    
    return signature;
}

// Based on CocoaSecurity
// https://github.com/kelp404/CocoaSecurity/blob/master/CocoaSecurity/CocoaSecurity.m

- (NSString *)encodeHex:(NSData *)data
{
    if (data.length == 0) { return nil; }
    
    static const char hexEncodeChars[] = "0123456789abcdef";
    char *resultData;
    // malloc result data
    resultData = malloc([data length] * 2 +1);
    // convert imgData(NSData) to char[]
    unsigned char *sourceData = ((unsigned char *)[data bytes]);
    NSUInteger length = [data length];
    
    for (NSUInteger index = 0; index < length; index++) {
        // set result data
        resultData[index * 2] = hexEncodeChars[(sourceData[index] >> 4)];
        resultData[index * 2 + 1] = hexEncodeChars[(sourceData[index] % 0x10)];
    }
    
    resultData[[data length] * 2] = 0;
    
    // convert result(char[]) to NSString
    NSString *result = [NSString stringWithCString:resultData encoding:NSUTF8StringEncoding];
    sourceData = nil;
    free(resultData);
    
    return result;
}

// Based on CocoaSecurity
// https://github.com/kelp404/CocoaSecurity/blob/master/CocoaSecurity/CocoaSecurity.m

- (NSData *)decodeHex:(NSString *)data
{
    if (data.length == 0) { return nil; }
    
    static const unsigned char HexDecodeChars[] =
    {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 1, //49
        2, 3, 4, 5, 6, 7, 8, 9, 0, 0, //59
        0, 0, 0, 0, 0, 10, 11, 12, 13, 14,
        15, 0, 0, 0, 0, 0, 0, 0, 0, 0,  //79
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 10, 11, 12,   //99
        13, 14, 15
    };
    
    // convert data(NSString) to CString
    const char *source = [data cStringUsingEncoding:NSUTF8StringEncoding];
    // malloc buffer
    unsigned char *buffer;
    NSUInteger length = strlen(source) / 2;
    buffer = malloc(length);
    for (NSUInteger index = 0; index < length; index++) {
        buffer[index] = (HexDecodeChars[source[index * 2]] << 4) + (HexDecodeChars[source[index * 2 + 1]]);
    }
    // init result NSData
    NSData *result = [NSData dataWithBytes:buffer length:length];
    free(buffer);
    source = nil;
    
    return  result;
}

- (void) dealloc {
    
}

@end
