//
//  Pass.h
//  Pass
//
//  Created by James Brennan on 2013-04-12.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/sysctl.h>
#import "PassError.h"
#import "FMDatabase.h"
#import "KeychainItemWrapper.h"
#import "SBJson.h"
#import "PACrypto.h"

@interface Pass : NSObject
@property(nonatomic,strong) FMDatabase *db;

+ (Pass *)sharedInstance;
- (bool)registerUser:(NSString*)email password:(NSString*)password error:(NSError**)error;
- (bool)deleteUser:(NSString*)email password:(NSString*)password error:(NSError**)error;
- (bool)login:(NSString*)email password:(NSString*)password error:(NSError**)error;
- (bool)registerWithService:(int)serviceId error:(NSError**)error;
- (bool)authenticate:(NSString *)token sessionId:(int)sessionId serviceId:(int)serviceId error:(NSError**)error;
- (NSDictionary *)post:(NSDictionary*)params endpoint:(NSString *)endpoint withToken:(bool)withToken response:(NSHTTPURLResponse**)response error:(NSError**)error;
- (NSDictionary *)delete:(NSDictionary*)params endpoint:(NSString *)endpoint withToken:(bool)withToken response:(NSHTTPURLResponse**)response error:(NSError**)error;
- (void)setAPIToken:(NSString*)token;
- (NSString *)getAPIToken;
- (bool)setServicePrivateKey:(int)serviceId privateKey:(NSString*)privateKey;
- (NSString *)getServicePrivateKey:(int)serviceId;
- (void)loadDb;
- (void)initDb;
- (NSString*)dbError;
- (NSString *)getDeviceModel;
- (NSString *)URLEncodedString:(NSString *)string;
- (void)firstRunCleanUp;
- (bool)validateEmail:(id *)ioValue error:(NSError **)outError;
- (bool)validatePassword:(id *)ioValue error:(NSError **)outError;
- (NSError *)createErrorWithMessage:(NSString *)userMessage parameter:(NSString *)parameter errorCode:(NSString *)errorCode devErrorMessage:(NSString *)devMessage;

@end
