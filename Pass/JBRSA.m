//
//  JBRSA.m
//  Pass
//
//  Created by James Brennan on 2013-04-06.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import "JBRSA.h"

@implementation JBRSA

- (id)init {
    
    if (self = [super init])
    {
        self.rsa = RSA_generate_key(2048, 37, NULL, NULL);
        
        if(self.rsa == NULL){
            NSLog(@"RSA_generate_key error: %lu", (unsigned long) ERR_get_error());
        }
    }
    
    return self;
}

- (id)initWithPrivateKey: (NSString *)privateKey {
    
    if (self = [super init])
    {
        [self loadPrivateKey:privateKey];
    }
    
    return self;
}

- (void)loadPrivateKey:(NSString*) key {
    const char *p = (char *)[key UTF8String];
    NSUInteger byteCount = [key lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    BIO *bufio;
    bufio = BIO_new_mem_buf((void*)p, byteCount);
    // Cannot send properties by reference - gets 'Address of property expression requested' error
    // Use a local variable instead for self.rsa
    RSA *r = self.rsa;
    
    r = PEM_read_bio_RSAPrivateKey(bufio, &r, NULL, NULL);
    
    if(r == NULL)
    {
        NSLog(@"PEM_read_bio_RSA_PUBKEY error: %lu", (unsigned long) ERR_get_error());
    }
    
    self.rsa = r;
}

- (NSString *)privateEncrypt:(NSString*)plaintext {
    unsigned char *from = (unsigned char *)[plaintext UTF8String];
    unsigned char *to = malloc(RSA_size(self.rsa));
    
    int success = RSA_private_encrypt((int) plaintext.length, from, to, self.rsa, RSA_PKCS1_PADDING);
    
    if( success == -1)
    {
        NSLog(@"RSA_private_encrypt error: %lu", (unsigned long) ERR_get_error());
    }
    
    return [NSString stringWithFormat:@"%s", to];
}
@end
