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
        //TODO Do we need to RAND_add here?
        NSLog(@"Start RSA gen");
        self.rsa = RSA_generate_key(1024, 65537, NULL, NULL);
        NSLog(@"End RSA gen");
        
        if(self.rsa == NULL)
        {
            NSLog(@"RSA_generate_key error: %lu", (unsigned long) ERR_get_error());
        }
        else
        {
            // Extact keys as pems
            BIO *bufio;
            int success;
            int keyLength;
            char *pemKey;
            
            // Get private key pem
            bufio = BIO_new(BIO_s_mem());
            success = PEM_write_bio_RSAPrivateKey(bufio, self.rsa, NULL, NULL, 0, NULL, NULL);
            
            if(success == 0)
            {
                NSLog(@"PEM_write_bio_RSAPrivateKey error: %lu", (unsigned long) ERR_get_error());
            }
            
            keyLength = BIO_pending(bufio);
            pemKey = calloc(keyLength + 1, 1);
            BIO_read(bufio, pemKey, keyLength);
            
            self.privateKey = [NSString stringWithFormat:@"%s", pemKey];
            
            // Get public key pem
            bufio = BIO_new(BIO_s_mem());
            success = PEM_write_bio_RSAPublicKey(bufio, self.rsa);
            
            if(success == 0)
            {
                NSLog(@"PEM_write_bio_RSAPublicKey error: %lu", (unsigned long) ERR_get_error());
            }
            
            keyLength = BIO_pending(bufio);
            pemKey = calloc(keyLength + 1, 1);
            BIO_read(bufio, pemKey, keyLength);
            
            self.publicKey = [NSString stringWithFormat:@"%s", pemKey];
            
            BIO_free_all(bufio);
        }
    }
    
    return self;
}

- (id)initWithPrivateKey: (NSString *)privateKey {
    
    if (self = [super init])
    {
        [self loadPrivateKey:privateKey];
        self.privateKey = privateKey;
    }
    
    return self;
}

- (void)loadPrivateKey:(NSString*) key {
    NSData* data = [key dataUsingEncoding:NSUTF8StringEncoding];
    BIO *bufio = BIO_new(BIO_s_mem());
    BIO_write(bufio, [data bytes], [data length]);
    
    // Cannot send properties by reference - gets 'Address of property expression requested' error
    // Use a local variable instead for self.rsa
    RSA *r = self.rsa;
    
    r = PEM_read_bio_RSAPrivateKey(bufio, &r, NULL, NULL);
    
    if(r == NULL)
    {
        unsigned long err = 0;
        while( (err = ERR_get_error()) )
        {
            NSLog(@"PEM_read_bio_RSAPrivateKey error: %lu", err);
        }
    }
    
    self.rsa = r;
    
    BIO_free_all(bufio);
}

- (NSString *)signature:(NSString*)token
{
//    EVP_PKEY *pkey = EVP_PKEY_new();
//    EVP_MD_CTX ctx;
//    unsigned int buf_len;
//    unsigned char * str;
//    char * data = (char *)[token cStringUsingEncoding:NSASCIIStringEncoding];
//    
//    if ( ! EVP_PKEY_assign_RSA(pkey, self.rsa))
//    {
//        unsigned long err = 0;
//        while( (err = ERR_get_error()) )
//        {
//            NSLog(@"RSA_private_encrypt error: %lu", err);
//        }
//    }
//    
//    EVP_MD_CTX_init(&ctx);
//    
//    EVP_SignInit(&ctx, EVP_get_digestbyname("SHA512"));
//    EVP_SignUpdate(&ctx, data, (unsigned int) sizeof(data));
//    str = malloc(EVP_PKEY_size(pkey) + 16);
//    if (!EVP_SignFinal(&ctx, str, &buf_len, pkey))
//    {
//        unsigned long err = 0;
//        while( (err = ERR_get_error()) )
//        {
//            NSLog(@"RSA_private_encrypt error: %lu", err);
//        }
//    }
//    
//    return [NSString stringWithFormat:@"%s", str];
    NSLog(@"Base64 token: %@", [self base64FromString:token encodeWithNewlines:YES]);
    NSString *signature;
    char *from = (char *)[token UTF8String];
    EVP_PKEY *evp_key = EVP_PKEY_new();
    EVP_MD_CTX ctx;
    unsigned char * sig_buf;
    unsigned int sig_len;
    
    if ( ! EVP_PKEY_assign_RSA(evp_key, self.rsa))
    {
        unsigned long err = 0;
        while( (err = ERR_get_error()) )
        {
            NSLog(@"RSA_private_encrypt error: %lu", err);
        }
    }

    EVP_MD_CTX_init(&ctx);
    
    sig_buf = malloc(EVP_PKEY_size(evp_key) + 16);
    
    if ( EVP_SignInit(&ctx, EVP_sha256()) != 1 )
    {
        unsigned long err = 0;
        while( (err = ERR_get_error()) )
        {
            NSLog(@"EVP_SignInit error: %lu", err);
        }
    }
    
    if ( EVP_SignUpdate (&ctx, from, strlen(from)) != 1 )
    {
        unsigned long err = 0;
        while( (err = ERR_get_error()) )
        {
            NSLog(@"EVP_SignUpdate error: %lu", err);
        }
    }
    
    if ( ! EVP_SignFinal (&ctx, sig_buf, &sig_len, evp_key)) {
        unsigned long err = 0;
        while( (err = ERR_get_error()) )
        {
            NSLog(@"RSA_private_encrypt error: %lu", err);
        }
    }

    signature = [NSString stringWithFormat:@"%s", sig_buf];
    
    free(sig_buf);
    EVP_PKEY_free (evp_key);
    EVP_MD_CTX_cleanup(&ctx);
    
    return signature;

//    EVP_PKEY_CTX *ctx;
//    unsigned char *md, *sig;
//    size_t mdlen, siglen;
//    EVP_PKEY *signing_key = EVP_PKEY_new();
//    ENGINE *e = ENGINE_get_first();
//    
//    md = (unsigned char *)[token cStringUsingEncoding:NSASCIIStringEncoding];
//    mdlen = (unsigned int) sizeof(md);
//    
//    if ( ! EVP_PKEY_assign_RSA(signing_key, self.rsa))
//    {
//        unsigned long err = 0;
//        while( (err = ERR_get_error()) )
//        {
//            NSLog(@"RSA_private_encrypt error: %lu", err);
//        }
//    }
//
//    /* NB: assumes signing_key, md and mdlen are already set up
//     * and that signing_key is an RSA private key
//     */
//    ctx = EVP_PKEY_CTX_new(signing_key, e);
//    if (!ctx)
//    /* Error occurred */
//    if (EVP_PKEY_sign_init(ctx) <= 0)
//    {
//        unsigned long err = 0;
//        while( (err = ERR_get_error()) )
//        {
//            NSLog(@"EVP_PKEY_sign_init error: %lu", err);
//        }
//    }
//        /* Error */
//    if (EVP_PKEY_CTX_set_rsa_padding(ctx, RSA_PKCS1_PADDING) <= 0)
//    {
//        unsigned long err = 0;
//        while( (err = ERR_get_error()) )
//        {
//            NSLog(@"EVP_PKEY_CTX_set_rsa_padding error: %lu", err);
//        }
//    }
//            /* Error */
//    if (EVP_PKEY_CTX_set_signature_md(ctx, EVP_sha512()) <= 0)
//    {
//        unsigned long err = 0;
//        while( (err = ERR_get_error()) )
//        {
//            NSLog(@"EVP_PKEY_CTX_set_signature_md error: %lu", err);
//        }
//    }
//                /* Error */
//                /* Determine buffer length */
//    if (EVP_PKEY_sign(ctx, NULL, &siglen, md, mdlen) <= 0)
//    {
//        unsigned long err = 0;
//        while( (err = ERR_get_error()) )
//        {
//            NSLog(@"EVP_PKEY_sign error: %lu", err);
//        }
//    }
//                    /* Error */
//    sig = malloc(siglen);
//    if (!sig)
//    {
//        NSLog(@"malloc error");
//        unsigned long err = 0;
//        while( (err = ERR_get_error()) )
//        {
//            NSLog(@"malloc error: %lu", err);
//        }
//    }
//        
//    if (EVP_PKEY_sign(ctx, sig, &siglen, md, mdlen) <= 0)
//    {
//        unsigned long err = 0;
//        while( (err = ERR_get_error()) )
//        {
//            NSLog(@"EVP_PKEY_sign error: %lu", err);
//        }
//    }
//        /* Error */
//    NSString *signature = [NSString stringWithFormat:@"%s", sig];
//    free(sig);
//    return signature;
}

- (NSString *)base64EncodeSignature:(NSString*)token
{
    NSLog(@"Token: %@", token);
    NSLog(@"Private key: %@", self.privateKey);
    NSLog(@"Public key: %@", self.publicKey);
    return [self base64FromString:[self signature:token] encodeWithNewlines:YES];
}

- (NSString *)base64FromString:(NSString *)string encodeWithNewlines:(BOOL)encodeWithNewlines {
    BIO *mem = BIO_new(BIO_s_mem());
    BIO *b64 = BIO_new(BIO_f_base64());
    
    if (!encodeWithNewlines) {
        BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
    }
    mem = BIO_push(b64, mem);
    
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger length = stringData.length;
    void *buffer = (void *) [stringData bytes];
    NSUInteger bufferSize = (NSUInteger) (long) MIN(length, (NSUInteger) INT_MAX);
    
    NSUInteger count = 0;
    
    BOOL error = NO;
    
    // Encode the data
    while (!error && count < length) {
        int result = BIO_write(mem, buffer, bufferSize);
        if (result <= 0) {
            error = YES;
        }
        else {
            count += result;
            buffer = (void *) [stringData bytes] + count;
            bufferSize = (NSUInteger) MIN((length - count), (NSUInteger) INT_MAX);
        }
    }
    
    int flush_result = BIO_flush(mem);
    if (flush_result != 1) {
        return nil;
    }
    
    char *base64Pointer;
    NSUInteger base64Length = (NSUInteger) BIO_get_mem_data(mem, &base64Pointer);
    
    NSData *base64data = [NSData dataWithBytesNoCopy:base64Pointer length:base64Length freeWhenDone:NO];
    NSString *base64String = [[NSString alloc] initWithData:base64data encoding:NSUTF8StringEncoding];
    
    BIO_free_all(mem);
    return base64String;
}

- (NSString *)sha512FromString:(NSString *)string {
    unsigned char *from = (unsigned char *) [[string dataUsingEncoding:NSASCIIStringEncoding] bytes];
    unsigned long length = [string length];
    unsigned char to[SHA512_DIGEST_LENGTH];
    NSMutableString *out = [NSMutableString string];
    
    SHA512_CTX sha512;
    SHA512_Init(&sha512);
    SHA512_Update(&sha512, from, length);
    SHA512_Final(to, &sha512);
    
    unsigned int i;
    for (i = 0; i < SHA512_DIGEST_LENGTH; i++) {
        [out appendFormat:@"%02x", to[i]];
    }
    return [out copy];
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

- (void) dealloc {
    
}

@end
