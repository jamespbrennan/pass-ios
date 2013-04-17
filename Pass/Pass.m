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
static NSString * const apiURLBase = @"https://api.passauth.net";
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

// Register user
//
// Create a user account
//

-(bool)registerUser:(NSString*)email password:(NSString*)password error:(NSError**)error
{
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] init];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:email forKey:@"email"];
    [params setObject:password forKey:@"password"];
    
    NSDictionary *json = [self post:params endpoint:@"/users" withToken:NO response:&response error:error];
    NSLog(@"%d", response.statusCode);
    if(response.statusCode == 200)
    {
        return YES;
    }
    else
    {
        if(error) NSLog(@"Register user error: %@", *error);
        
        // Get error message from server
        NSDictionary *jsonError = [json objectForKey:@"error"];
        
        if([jsonError objectForKey:@"message"])
            NSLog(@"Register user error: %@", [jsonError objectForKey:@"message"]);
        else
            NSLog(@"Register user error but no error message returned from server.");
        
        return NO;
    }
}

// Login
//
// Login with a username/password. Creates a device on the server attached to the user who logged in.
//

-(bool)login:(NSString*)email password:(NSString*)password error:(NSError**)error
{
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] init];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:email forKey:@"email"];
    [params setObject:password forKey:@"password"];
    [params setObject:[[UIDevice currentDevice] name] forKey:@"name"];
    [params setObject:[self getDeviceModel] forKey:@"device_identifier"];
    NSDictionary *json = [self post:params endpoint:@"/devices" withToken:NO response:&response error:error];
    
    if(response.statusCode == 200)
    {
        NSString *token = [json objectForKey:@"token"];
        
        if( [token isEqualToString:@""] )
        {
            return NO;
        }
        else
        {
            [self setDeviceAPIToken:token];
            return YES;
        }
    }
    else
    {
        if(error) NSLog(@"Login error: %@", *error);
        
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
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] init];
    NSError *error = [[NSError alloc] init];
    
    // Prepare parameters
    JBRSA *rsa = [[JBRSA alloc] init];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
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

-(bool)authenticate:(NSString *)token sessionId:(int)sessionId serviceId:(int)serviceId error:(NSError**)error
{
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] init];
    
    JBRSA *rsa = [[JBRSA alloc] initWithPrivateKey:[self getServicePrivateKey:serviceId]];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[[NSString alloc] initWithFormat:@"%d", sessionId] forKey:@"id"];
    [params setObject:[rsa privateEncrypt:token] forKey:@"token"];
    
    NSDictionary *responseData = [self post:params endpoint:@"/sessions/authenticate" withToken:YES response:&response error:error];
    
    if ([response statusCode] != 200)
    {
        // Log the NSURLConnection error, if any
        if (*error) NSLog(@"Login error: %@", *error);
        
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

// Post
//
// Execute a post request to the server.
//

-(NSDictionary *)post:(NSDictionary*)params endpoint:(NSString *)endpoint withToken:(bool)withToken response:(NSHTTPURLResponse**)response error:(NSError**)error
{
    SBJsonParser *jsonParser = [SBJsonParser new];
    NSData *responseData = [[NSData alloc] init];
    
    // Setup post
    NSMutableString *post = [NSMutableString string];
    
    for (NSString* key in params){
        NSString *value = [params objectForKey:key];
        if ((id)value == [NSNull null]) continue;
        
        if ([post length] != 0)
            [post appendString:@"&"];
        
        if ([value isKindOfClass:[NSString class]])
            value = [self URLEncodedString:value];
        
        [post appendFormat:@"%@=%@", key, value];
    }
    
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString: [[NSString alloc] initWithFormat:@"%@%@", apiURLBase, endpoint]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    if(withToken)
    {
        [request setValue:[[NSString alloc] initWithFormat:@"Token %@", [self getAPIToken]] forHTTPHeaderField:@"Authorization"];
    }
    
    responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:response error:error];
    
    return (NSDictionary *) [jsonParser objectWithString:[[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding]];
}

// Set API Token
//
// Store the device API token in the keychain
//

-(void)setDeviceAPIToken:(NSString*)token
{
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"Token" accessGroup:nil];
    [keychain setObject:@"DeviceAPIToken" forKey:(__bridge id)(kSecAttrAccount)];
    [keychain setObject:token forKey:(__bridge id)(kSecValueData)];
}

// Get API Token
//
// Get the device API token from the keychain.
//

-(NSString *)getAPIToken
{
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"Token" accessGroup:nil];
    return [keychain objectForKey:(id)CFBridgingRelease(kSecValueData)];
}

// Set Service Private Key
//
// Store a private key in the keychain for a given service.
//

- (bool) setServicePrivateKey:(int)serviceId privateKey:(NSString*)privateKey
{
    NSString * keyName = [[NSString alloc] initWithFormat:@"ServicePrivateKey%d", serviceId];
    
    // Store the private key in the keychain
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:keyName accessGroup:nil];
    [keychain setObject:keyName forKey:(__bridge id)(kSecAttrAccount)];
    [keychain setObject:privateKey forKey:(__bridge id)(kSecValueData)];
    
    // Insert record for the service
    return [self.db executeQuery:@"INSERT OR REPLACE INTO services (id, key_name) VALUES(?, ?)", [NSNumber numberWithInteger:serviceId], keyName];
}

// Get Service Private Key
//
// Get a private key from the keychain for a given service. Returns `nil` if none found.
//

- (NSString *) getServicePrivateKey:(int)serviceId
{
    FMResultSet *s = [self.db executeQuery:@"SELECT key_name FROM services WHERE id = (?) LIMIT 1", [NSNumber numberWithInteger:serviceId]];
    if ([s next] && [s stringForColumn:@"key_name"]) {
        KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:[s stringForColumn:@"key_name"] accessGroup:nil];
        return [keychain objectForKey:[s stringForColumn:@"key_name"]];
    } else {
        return nil;
    }
}

// Load DB
//
// Open and initialize the database.
//

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
}

- (void) initDb {
    // --- Make sure the necessary tables exist
    
    // Services
    if ( ! [self.db executeQuery:@"CREATE TABLE IF NOT EXISTS services (id INTEGER PRIMARY KEY, key_name TEXT)"] )
    {
        NSLog(@"%@", [self dbError]);
    }
}

// DB Error
//
// Log the last database error.
//

- (NSString*)dbError
{
    return [[NSString alloc] initWithFormat:@"Database error %d: %@", [self.db lastErrorCode], [self.db lastErrorMessage]];
}

// Get Device Model
//
// Get the device's model.
//

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

// URL Encoded String
//
//
//

- (NSString *)URLEncodedString:(NSString *)string {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)string, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
}

// Cleanup
//
// Cleanup files on first run that could still be around after uninstalling the app
//

-(void)firstRunCleanUp
{
    // Clean the device token
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"Token" accessGroup:nil];
    [keychain resetKeychainItem];
    
    // Services
    if ( ! [self.db executeQuery:@"DROP TABLE IF EXISTS services"] )
    {
        NSLog(@"%@", [self dbError]);
    }
}
@end
