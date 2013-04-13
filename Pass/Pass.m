//
//  Pass.m
//  Pass
//
//  Created by James Brennan on 2013-04-12.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import "Pass.h"

@implementation Pass
static NSString * const apiURLBase = @"api.passauth.net";
static NSString * const apiVersion = @"v1";

+(bool)registerUser:(NSString*)email password:(NSString*)password
{
    return YES;
}

+(bool)login:(NSString*)email password:(NSString*)password
{
    NSHTTPURLResponse *response;
    NSError *error;
    NSMutableDictionary *params;
    [params setObject:email forKey:@"email"];
    [params setObject:password forKey:@"password"];
    [params setObject:[[UIDevice currentDevice] name] forKey:@"name"];
    [params setObject:[self getModel] forKey:@"device_identifier"];
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

+(NSDictionary *)registerDevice:(int)serviceId
{
    NSHTTPURLResponse *response;
    NSError *error;
    NSMutableDictionary *params;
    [params setObject:[[NSString alloc] initWithFormat:@"%d", serviceId] forKey:@"service_id"];
    NSString *responseData;
    SBJsonParser *jsonParser = [SBJsonParser new];
    
    responseData = [[NSString alloc]initWithData:[self post:params endpoint:@"/devices/register" withToken:NO response:&response error:&error] encoding:NSUTF8StringEncoding];
    
    return (NSDictionary *) [jsonParser objectWithString:responseData];
}

+(void)authenticate
{
    
}

+(bool)setToken:(NSString*)token
{
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"Token" accessGroup:@"Pass"];
    [wrapper setObject:token forKey:(id)CFBridgingRelease(kSecValueData)];
}

+(NSString *)getToken
{
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"Token" accessGroup:nil];
    return [wrapper objectForKey:(id)CFBridgingRelease(kSecValueData)];
}

+(NSDictionary *)post:(NSMutableDictionary*)params endpoint:(NSString *)endpoint withToken:(bool)withToken response:(NSHTTPURLResponse**)response error:(NSError**)error
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

+ (NSString*)dbError:(FMDatabase *)db
{
    return [[NSString alloc] initWithFormat:@"Database error %d: %@", [db lastErrorCode], [db lastErrorMessage]];
}

+ (NSString*)dbPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingPathComponent:@"/pass.db"];
}

+ (NSString *)getModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *model = malloc(size);
    sysctlbyname("hw.machine", model, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
    free(model);
    return deviceModel;
}

@end
