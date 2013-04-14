//
//  Pass.m
//  Pass
//
//  Created by James Brennan on 2013-04-12.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import "Pass.h"

@implementation Pass
static Pass *sharedInstance = nil;
static NSString * const apiURLBase = @"api.passauth.net";
static NSString * const apiVersion = @"v1";

+ (Pass *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Pass alloc] init];
        
        [sharedInstance loadDb];
    });
    return sharedInstance;
}

-(bool)registerUser:(NSString*)email password:(NSString*)password
{
    return YES;
}

// Login
//
// Login with a username/password. Creates a device on the server attached to the user who logged in.
//
-(bool)login:(NSString*)email password:(NSString*)password
{
    NSHTTPURLResponse *response;
    NSError *error;
    NSMutableDictionary *params;
    [params setObject:email forKey:@"email"];
    [params setObject:password forKey:@"password"];
    [params setObject:[[UIDevice currentDevice] name] forKey:@"name"];
    [params setObject:[self getDeviceModel] forKey:@"device_identifier"];
    NSDictionary *json = [self post:params endpoint:@"/devices" withToken:NO response:&response error:&error];
    
    if(response.statusCode == 200)
    {
        NSString *token = [json objectForKey:@"token"];
        
        if( [token isEqualToString:@""] )
        {
            return NO;
        }
        else
        {
            [self setToken:token];
            return YES;
        }
    }
    else
    {
        if(error) NSLog(@"Login error: %@", error);
        
        // Get error message from server
        NSDictionary *jsonError = [json objectForKey:@"error"];
        
        if([jsonError objectForKey:@"message"])
            NSLog(@"Login error: %@", [jsonError objectForKey:@"message"]);
        else
            NSLog(@"Login error but no error message returned from server.");
        
        return NO;
    }
}

// Register
//
// Register the device to a service. Creates a RSA keypair for the specific service and stores it in the keychain.
//

-(bool)register:(int)serviceId
{
    NSHTTPURLResponse *response;
    NSError *error;
    
    // Prepare parameters
    JBRSA *rsa = [JBRSA init];
    NSMutableDictionary *params;
    [params setObject:rsa.publicKey forKey:@"public_key"];
    [params setObject:[[NSString alloc] initWithFormat:@"%d", serviceId] forKey:@"service_id"];
    
    NSDictionary *responseData = [self post:params endpoint:@"/devices/register" withToken:YES response:&response error:&error];
    
    if(response.statusCode != 200)
    {
        if(error) NSLog(@"Register error: %@", error);
        
        NSDictionary *responseDataError = [responseData objectForKey:@"error"];
        NSLog(@"Register error: %@ Status code: %d", [responseDataError objectForKey:@"message"], response.statusCode);
        
        return NO;
    }
    
    // Store the private key in the keychain
    [self setServicePrivateKey:serviceId privateKey:rsa.privateKey];
    
    return YES;
}

// Authenticate
//
// Authenticate for a given session and service.
//

-(bool)authenticate:(NSString *)token sessionId:(int)sessionId serviceId:(int)serviceId
{
    NSHTTPURLResponse *response;
    NSError *error;
    
    JBRSA *rsa = [[JBRSA alloc] initWithPrivateKey:[self getServicePrivateKey:serviceId]];
    
    NSMutableDictionary *params;
    [params setObject:[[NSString alloc] initWithFormat:@"%d", sessionId] forKey:@"id"];
    [params setObject:[rsa privateEncrypt:token] forKey:@"token"];
    
    NSDictionary *responseData = [self post:params endpoint:@"/sessions/authenticate" withToken:YES response:&response error:&error];
    
    if ([response statusCode] != 200)
    {
        // Log the NSURLConnection error, if any
        if (error) NSLog(@"Login error: %@", error);
        
        NSString *message = [responseData objectForKey:@"error[message]"];
        NSLog(@"Login error: %@", message);
        return nil;
    }
    
    if ( ! (bool) [responseData objectForKey:@"is_authenticated"])
    {
        return NO;
    }
    
    return YES;
}

-(void)setToken:(NSString*)token
{
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"Token" accessGroup:@"Pass"];
    [wrapper setObject:token forKey:(id)CFBridgingRelease(kSecValueData)];
}

-(NSString *)getToken
{
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"Token" accessGroup:nil];
    return [wrapper objectForKey:(id)CFBridgingRelease(kSecValueData)];
}

-(NSDictionary *)post:(NSMutableDictionary*)params endpoint:(NSString *)endpoint withToken:(bool)withToken response:(NSHTTPURLResponse**)response error:(NSError**)error
{
    SBJsonParser *jsonParser = [SBJsonParser new];
    
    // Setup post
    NSMutableString *post = [NSMutableString string];
    
    for (NSString* key in [params allKeys]){
        if ([post length]>0)
            [post appendString:@"&"];
        [post appendFormat:@"%@=%@", key, [params objectForKey:key]];
    }
    
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    
    NSURL *url=[NSURL URLWithString: [[NSString alloc] initWithFormat:@"%@%@", apiURLBase, endpoint]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    if(withToken)
    {
        NSString *token = [[NSString alloc] initWithFormat:@"Token %@", [self getToken]];
        [request setValue:token forHTTPHeaderField:@"Authorization"];
    }
    
    response = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:response error:error];
    
    return (NSDictionary *) [jsonParser objectWithString:[[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding]];
}

- (bool) setServicePrivateKey:(int)serviceId privateKey:(NSString*)privateKey
{
    NSString * keyName = [[NSString alloc] initWithFormat:@"ServicePrivateKey%d", serviceId];
    
    // Store the private key in the keychain
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:keyName accessGroup:@"Pass"];
    [wrapper setObject:privateKey forKey:(id)CFBridgingRelease(kSecValueData)];
    
    // Insert record for the service
    return [self.db executeQuery:@"INSERT OR REPLACE INTO services (id, key_name) VALUES(?, ?)", [NSNumber numberWithInteger:serviceId], keyName];
}

- (NSString *) getServicePrivateKey:(int)serviceId
{
    FMResultSet *s = [self.db executeQuery:@"SELECT key_name FROM services WHERE id = (?) LIMIT 1", [NSNumber numberWithInteger:serviceId]];
    if ([s next] && [s stringForColumn:@"key_name"]) {
        KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:[s stringForColumn:@"key_name"] accessGroup:@"Pass"];
        return [wrapper objectForKey:[s stringForColumn:@"key_name"]];
    } else {
        return nil;
    }
}

- (void)loadDb
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    self.db = [FMDatabase databaseWithPath:[documentsDirectory stringByAppendingPathComponent:@"/pass.db"]];
    
    // Open the database
    if ( ! [self.db open] )
    {
        NSLog(@"%@", [self dbError]);
    }
    else
    {
        // --- Make sure the necessary tables exist
        
        // Services
        if ( ! [self.db executeQuery:@"CREATE TABLE IF NOT EXISTS services (id INTEGER PRIMARY KEY, key_name TEXT)"] )
        {
            NSLog(@"%@", [self dbError]);
        }
    }
}

- (NSString*)dbError
{
    return [[NSString alloc] initWithFormat:@"Database error %d: %@", [self.db lastErrorCode], [self.db lastErrorMessage]];
}

- (NSString *)getDeviceModel
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *model = malloc(size);
    sysctlbyname("hw.machine", model, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
    free(model);
    return deviceModel;
}

@end
