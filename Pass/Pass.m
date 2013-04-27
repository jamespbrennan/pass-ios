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
    // Validate request
    if( ! [self validateEmail:&email error:error])
    {
        return NO;
    }
    
    if( ! [self validatePassword:&password error:error])
    {
        return NO;
    }
    
    // Prepare request
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] init];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:email forKey:@"email"];
    [params setObject:password forKey:@"password"];
    
    NSDictionary *json = [self post:params endpoint:@"/users" withToken:NO response:&response error:error];

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
    // Validate request
    if( ! [self validateEmail:&email error:error])
    {
        return NO;
    }
    
    if( ! [self validatePassword:&password error:error])
    {
        return NO;
    }
    
    // Prepare request
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
        
        // If its a 401, show a more friendly message to the user
        if([*error code] == -1012)
        {
            NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : PAEmailPasswordAuthenticationErrorMessage };
            *error = [[NSError alloc] initWithDomain:PassDomain code:401 userInfo:userInfoDict];
        }
        
        return NO;
    }
}

// Register
//
// Register the device to a service. Creates a RSA keypair for the specific service and stores it in the keychain.
//

-(bool)registerWithService:(int)serviceId error:(NSError**)error
{
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] init];
    
    // Prepare parameters
    PANaCL *nacl = [[PANaCL alloc] init];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:nacl.publicKey forKey:@"public_key"];
    [params setObject:[[NSString alloc] initWithFormat:@"%d", serviceId] forKey:@"service_id"];
    
    NSDictionary *responseData = [self post:params endpoint:@"/devices/register" withToken:YES response:&response error:error];
    
    // NSURLRequest error
    if([response statusCode] == 0)
    {
        // HTTP 401 (bad device api token)
        if ( [*error code] == -1012 )
        {
            *error = [self createErrorWithMessage:PAFailedAuthenticationMessage parameter:@"token" errorCode:PAFailedAuthentication devErrorMessage:@"Invalid Device API Token."];
        }
        else
        {
            NSLog(@"Login error: %@ %@", *error, [*error userInfo]);
            
            *error = [self createErrorWithMessage:PAServerErrorMessage parameter:@"token" errorCode:PAServerError devErrorMessage:@"Authenticate: communication error."];
        }
        
        return NO;
    }
    
    // HTTP 500 Server error
    if([response statusCode] == 500)
    {
        *error = [self createErrorWithMessage:PAServerErrorMessage parameter:@"token" errorCode:PAServerError devErrorMessage:@"Authenticate: 500 server error."];
        return NO;
    }
    
    // Something else
    if([response statusCode] != 200)
    {
        NSDictionary *responseDataError = [responseData objectForKey:@"error"];
        NSString *message = [[NSString alloc] initWithFormat:@"Authenticate error: %@ Status code: %d", [responseDataError objectForKey:@"message"], response.statusCode];
        NSLog(@"%@", message);
        
        *error = [self createErrorWithMessage:PAServerErrorMessage parameter:@"token" errorCode:PAServerError devErrorMessage:message];
        
        return NO;
    } 
    
    // Store the private key in the keychain
    [self setServicePrivateKey:serviceId privateKey:nacl.privateKey];
    
    return YES;
}

// Authenticate
//
// Authenticate for a given session and service.
//

-(bool)authenticate:(NSString *)token sessionId:(int)sessionId serviceId:(int)serviceId error:(NSError**)error
{
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] init];
    
    PANaCL *rsa = [[PANaCL alloc] initWithPrivateKey:[self getServicePrivateKey:serviceId]];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[[NSString alloc] initWithFormat:@"%d", sessionId] forKey:@"id"];
    [params setObject:[rsa signature:token] forKey:@"token"];
    
    NSLog(@"sig: %@", [params objectForKey:@"token"]);
    
    NSDictionary *responseData = [self post:params endpoint:@"/sessions/authenticate" withToken:YES response:&response error:error];
    
    // NSURLRequest error
    if([response statusCode] == 0)
    {
        // HTTP 401
        if ( [*error code] == -1012 )
        {
            *error = [self createErrorWithMessage:PAFailedAuthenticationMessage parameter:@"token" errorCode:PAFailedAuthentication devErrorMessage:@"Password must not be blank."];
        }
        else
        {
            NSLog(@"Login error: %@ %@", *error, [*error userInfo]);
            
            *error = [self createErrorWithMessage:PAServerErrorMessage parameter:@"token" errorCode:PAServerError devErrorMessage:@"Authenticate: communication error."];
        }
        
        return NO;
    }
    
    // HTTP 500 Server error
    if([response statusCode] == 500)
    {
        *error = [self createErrorWithMessage:PAServerErrorMessage parameter:@"token" errorCode:PAServerError devErrorMessage:@"Authenticate: 500 server error."];
        return NO;
    }
    
    // Something else
    if([response statusCode] != 200)
    {
        NSDictionary *responseDataError = [responseData objectForKey:@"error"];
        NSString *message = [[NSString alloc] initWithFormat:@"Authenticate error: %@ Status code: %d", [responseDataError objectForKey:@"message"], response.statusCode];
        NSLog(@"%@", message);
        
        *error = [self createErrorWithMessage:PAServerErrorMessage parameter:@"token" errorCode:PAServerError devErrorMessage:message];
        
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
    if ([self.db executeUpdate:@"INSERT OR REPLACE INTO services (id, key_name) VALUES(?, ?)", [NSNumber numberWithInteger:serviceId], keyName])
    {
        return YES;
    }
    else
    {
        NSLog(@"setServicePrivateKey database error: %@", [self dbError]);
        return NO;
    }
}

// Get Service Private Key
//
// Get a private key from the keychain for a given service. Returns `nil` if none found.
//

- (NSString *) getServicePrivateKey:(int)serviceId
{
    FMResultSet *s = [self.db executeQuery:@"SELECT key_name FROM services WHERE id = (?) LIMIT 1", [NSNumber numberWithInteger:serviceId]];
    
    if( s == nil)
    {
        NSLog(@"getServicePrivateKey database error: %@", [self dbError]);
        return nil;
    }
    
    if ([s next] && [s stringForColumn:@"key_name"]) {
        KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:[s stringForColumn:@"key_name"] accessGroup:nil];
        return [keychain objectForKey:(__bridge id)(kSecValueData)];
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
    self.db = [FMDatabase databaseWithPath:[documentsDirectory stringByAppendingPathComponent:@"/pass.sqlite3"]];
    
    // Open the database
    if ( ! [self.db open] )
    {
        NSLog(@"loadDB database error: %@", [self dbError]);
    }
}

// Init DB
//
// Make sure the necessary tables exist
//

- (void) initDb {
    NSLog(@"Initalizing database...");
    // Services
    if ( ! ([self.db executeUpdate:@"CREATE TABLE IF NOT EXISTS services (id INTEGER PRIMARY KEY, key_name TEXT)"]) )
    {
        NSLog(@"initDB database error: %@", [self dbError]);
    }
}

// DB Error
//
// Get the last database error.
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

// First Run Cleanup
//
// Cleanup files on first run that could still be around after uninstalling the app
//

- (void)firstRunCleanUp
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

// Validate Email
//
// Validate presence and format of an email.
//

- (bool) validateEmail:(id *)ioValue error:(NSError **)outError
{
    NSString *checkString = [(NSString *)*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"];
    
    if (*ioValue == nil || ! [emailTest evaluateWithObject:checkString])
    {
        *outError = [self createErrorWithMessage:PAInvalidEmailMessage parameter:@"email" errorCode:PAInvalidEmail devErrorMessage:@"Email must contain a valid email address."];
        return NO;
    }
    
    return YES;
}

// Validate Password
//
// Validate the presence of a password.
//
- (bool) validatePassword:(id *)ioValue error:(NSError **)outError
{
    NSString *checkString = (NSString *)*ioValue;
    
    if (*ioValue == nil || checkString.length == 0)
    {
        *outError = [self createErrorWithMessage:PAInvalidPasswordMessage parameter:@"password" errorCode:PAInvalidPassword devErrorMessage:@"Password must not be blank."];
        return NO;
    }
    
    return YES;
}

// Create Error With Message
//
// Create an error message with a user facing localized description.
//

- (NSError *)createErrorWithMessage:(NSString *)userMessage parameter:(NSString *)parameter errorCode:(NSString *)errorCode devErrorMessage:(NSString *)devMessage {
    NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey:userMessage, PAErrorParameterKey:parameter, PAErrorCodeKey:errorCode,PAErrorMessageKey:devMessage };
    
    return [[NSError alloc] initWithDomain:PassDomain code:PAInvalidParameterError userInfo:userInfoDict];
}

@end
