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
        [self setupOpenSSL];
        
        NSLog(@"Start RSA gen");
        self.rsa = RSA_generate_key(2048, 65537, NULL, NULL);
        NSLog(@"End RSA gen");
        
        if(self.rsa == NULL)
        {
            [self handleOpenSSLError:@"RSA_generate_key"];
        }
        else
        {
            // Make sure everything is ok
            if(RSA_check_key(self.rsa) <= 0)
            {
                [self handleOpenSSLError:@"RSA_check_key error"];
            }
            
            // Extact keys as pems
            BIO *bufio;
            int keyLength;
            char *pemKey;
            
            // Get private key pem
            bufio = BIO_new(BIO_s_mem());
            
            if(PEM_write_bio_RSAPrivateKey(bufio, self.rsa, NULL, NULL, 0, NULL, NULL) == 0)
            {
                [self handleOpenSSLError:@"PEM_write_bio_RSAPrivateKey error"];
            }
            
            keyLength = BIO_pending(bufio);
            pemKey = calloc(keyLength + 1, 1);
            BIO_read(bufio, pemKey, keyLength);
            
            self.privateKey = [NSString stringWithFormat:@"%s", pemKey];
            
            // Get public key pem
            bufio = BIO_new(BIO_s_mem());
            
            if(PEM_write_bio_RSAPublicKey(bufio, self.rsa) == 0)
            {
                [self handleOpenSSLError:@"PEM_write_bio_RSAPublicKey error"];
            }
            
            keyLength = BIO_pending(bufio);
            pemKey = calloc(keyLength + 1, 1);
            BIO_read(bufio, pemKey, keyLength);
            
            self.publicKey = [NSString stringWithFormat:@"%s", pemKey];
            
            BIO_free_all(bufio);
            
            NSLog(@"Public key: %@", self.publicKey);
            NSLog(@"Private key: %@", self.privateKey);
        }
    }
    
    return self;
}

- (id)initWithPrivateKey: (NSString *)privateKey {
    
    if (self = [super init])
    {
        [self loadPrivateKey:privateKey];
        self.privateKey = privateKey;
        
        // Make sure everything is ok
        if(RSA_check_key(self.rsa) <= 0)
        {
            [self handleOpenSSLError:@"RSA_check_key error"];
        }
    }
    
    return self;
}

- (void)setupOpenSSL
{
    ERR_load_crypto_strings();
    
    //TODO Do we need to RAND_add here?
    
    if(SSL_library_init())
    {
        SSL_load_error_strings();
        OpenSSL_add_all_algorithms();
    }
    
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
        [self handleOpenSSLError:@"PEM_read_bio_RSAPrivateKey error"];
    }
    
    self.rsa = r;
    
    BIO_free_all(bufio);
}

- (NSString *)signature:(NSString*)token
{
    NSString *signature;
//    char *plaintext = (char *)[token UTF8String];
//    EVP_PKEY *evp_key = EVP_PKEY_new();
//    EVP_MD_CTX ctx;
//    unsigned char * sig_buf;
//    unsigned int sig_len;
//    
//    if ( ! EVP_PKEY_assign_RSA(evp_key, self.rsa))
//    {
//        [self handleOpenSSLError:@"EVP_PKEY_assign_RSA error"];
//    }
//
//    EVP_MD_CTX_init(&ctx);
//    
//    sig_buf = malloc(EVP_PKEY_size(evp_key));
//    
//    if ( EVP_DigestSignInit(&ctx, EVP_sha512()) != 1 )
//    {
//        [self handleOpenSSLError:@"EVP_SignInit error"];
//    }
//    
//    if ( EVP_DigestSignUpdate (&ctx, plaintext, strlen(plaintext)) != 1 )
//    {
//        [self handleOpenSSLError:@"EVP_SignUpdate error"];
//    }
//    
//    if ( EVP_DigestSignFinal (&ctx, sig_buf, &sig_len, evp_key) != 1) {
//        [self handleOpenSSLError:@"EVP_SignFinal error"];
//    }
//
//    signature = [NSString stringWithFormat:@"%s", sig_buf];
//    
//    free(sig_buf);
//    EVP_PKEY_free (evp_key);
//    EVP_MD_CTX_cleanup(&ctx);
//
//    return signature;
    EVP_PKEY_CTX *ctx;
    const unsigned char *md = (const unsigned char *)[token UTF8String];
    unsigned char *sig;
    size_t mdlen = strlen((const char *)md);
    size_t siglen;
    EVP_PKEY *signing_key = EVP_PKEY_new();
    ENGINE *e = ENGINE_get_default_RSA();
    
    if ( ! EVP_PKEY_assign_RSA(signing_key, self.rsa))
    {
        [self handleOpenSSLError:@"EVP_PKEY_assign_RSA error"];
    }

    ctx = EVP_PKEY_CTX_new(signing_key, e);
    if (!ctx)
    {
        [self handleOpenSSLError:@"PEM_read_bio_RSAPrivateKey error"];
    }
    /* Error occurred */
    if (EVP_PKEY_sign_init(ctx) <= 0)
    {
        [self handleOpenSSLError:@"EVP_PKEY_sign_init error"];
    }
    
    if (EVP_PKEY_CTX_set_rsa_padding(ctx, RSA_X931_PADDING) <= 0)
    {
        [self handleOpenSSLError:@"EVP_PKEY_CTX_set_rsa_padding error"];
    }
    if (EVP_PKEY_CTX_set_signature_md(ctx, EVP_sha256()) <= 0)
    {
        [self handleOpenSSLError:@"EVP_PKEY_CTX_set_signature_md error"];
    }
    if (EVP_PKEY_sign(ctx, NULL, &siglen, md, mdlen) <= 0)
    {
        [self handleOpenSSLError:@"EVP_PKEY_sign NULL error"];
    }
    sig = OPENSSL_malloc(siglen);
    
    if (!sig)
    {
        [self handleOpenSSLError:@"sig error"];
    }
    if (EVP_PKEY_sign(ctx, sig, &siglen, md, mdlen) <= 0)
    {
        [self handleOpenSSLError:@"EVP_PKEY_sign error"];
    }
    
    signature = [NSString stringWithFormat:@"%s", sig];
    
//    free(sig);
    EVP_cleanup();

    return signature;
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
    
    if ( ! encodeWithNewlines) {
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

- (NSString *)privateEncrypt:(NSString *)plaintext {
    unsigned char *from = (unsigned char *)[plaintext UTF8String];
    unsigned char *to = malloc(RSA_size(self.rsa));
    
    int success = RSA_private_encrypt((int) plaintext.length, from, to, self.rsa, RSA_PKCS1_PADDING);
    
    if( success == -1)
    {
        [self handleOpenSSLError:@"RSA_private_encrypt error"];
    }
    
    return [NSString stringWithFormat:@"%s", to];
}

- (void) handleOpenSSLError:(NSString *)message {
    NSLog(@"%@", message);
    ERR_print_errors_fp(stderr);
    
    unsigned long err = 0;
    while( (err = ERR_get_error()) )
    {
        NSLog(@"%@: %lu", message, err);
    }
}

- (void) dealloc {
    
}

@end
