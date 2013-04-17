//
//  Pass.h
//  Pass
//
//  Created by James Brennan on 2013-04-12.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/sysctl.h>
#import "FMDatabase.h"
#import "KeychainItemWrapper.h"
#import "SBJson.h"
#import "JBRSA.h"

@interface Pass : NSObject
@property(nonatomic,strong) FMDatabase *db;

+ (Pass *)sharedInstance;
-(bool)registerUser:(NSString*)email password:(NSString*)password error:(NSError**)error;
-(bool)login:(NSString*)email password:(NSString*)password error:(NSError**)error;
-(bool)register:(int)serviceId;
-(bool)authenticate:(NSString *)token sessionId:(int)sessionId serviceId:(int)serviceId error:(NSError**)error;
-(void)setDeviceAPIToken:(NSString*)token;
-(NSString *)getAPIToken;
-(NSDictionary *)post:(NSMutableDictionary*)params endpoint:(NSString *)endpoint withToken:(bool)withToken response:(NSHTTPURLResponse**)response error:(NSError**)error;
- (bool) setServicePrivateKey:(int)serviceId privateKey:(NSString*)privateKey;
- (NSString *) getServicePrivateKey:(int)serviceId;
- (void)loadDb;
- (void)initDb;
- (NSString*)dbError;
- (NSString *)getDeviceModel;
- (void)firstRunCleanUp;
@end
