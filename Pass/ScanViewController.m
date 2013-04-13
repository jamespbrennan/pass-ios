//
//  ScanViewController.m
//  Pass
//
//  Created by James Brennan on 2013-04-03.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import "ScanViewController.h"

@interface ScanViewController ()

@end

@implementation ScanViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.capture = [[ZXCapture alloc] init];
    self.capture.delegate = self;
    self.capture.rotation = 90.0f;
    
    // Use the back camera
    self.capture.camera = self.capture.back;
    
    self.capture.layer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.capture.layer];
}

- (void)captureResult:(ZXCapture*)capture result:(ZXResult*)result {
    if (result) {
        // Vibrate
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        NSArray *chunks = [result.text componentsSeparatedByString: @":"];
        
        

        if(chunks.count < 3)
        {
            // Extract values from QR code
            int sessionId = [chunks[0] intValue];
            int serviceId = [chunks[1] intValue];
            NSString *token = chunks[2];
            NSString *keyName = [self getServiceKeyName:serviceId];
            
            if(keyName)
            {
                [self authenticate:token serviceId:serviceId sessionId:sessionId keyName:keyName];
            }
            else
            {
                // Register first, then authenticate
                keyName = [self register:serviceId];
                [self authenticate:token serviceId:serviceId sessionId:sessionId keyName:keyName];
            }
            
        }
    }
}

- (NSString*)register:(int)serviceId
{
    NSString *keyName = [[NSString alloc] initWithFormat:@"privateKeyService%d", serviceId];
    
    // Create a keypair
    JBRSA *rsa = [[JBRSA alloc] init];
    
    // Store the private key
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"Token" accessGroup:@"Pass"];
    [wrapper setObject:rsa.privateKey forKey:(id)CFBridgingRelease(kSecValueData)];
    [self setServiceKeyName:serviceId keyName:keyName];
    
    // Send off the public key
    NSString *post = [[NSString alloc] initWithFormat:@"public_key=%@&service_id=%d", rsa.publicKey, serviceId];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    
    NSURL *url = [NSURL URLWithString:@"https://api.passauth.net/devices"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *response = nil;
    NSData *urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if ([response statusCode] != 200)
    {
        // Log the NSURLConnection error, if any
        if (error) NSLog(@"Login error: %@", error);
        
        // Log Pass API error
        NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
        SBJsonParser *jsonParser = [SBJsonParser new];
        NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData];
        NSString *message = [jsonData objectForKey:@"error[message]"];
        NSLog(@"Login error: %@", message);
        
        [self alertStatus: @"Sorry, something went wrong on our end. Please try logging in again." :@"Error"];
        
        return nil;
    }
 
    return keyName;
}

- (bool)authenticate:(NSString*)token serviceId:(int)serviceId sessionId:(int)sessionId keyName:(NSString*)keyName {
    NSString *keychainLookup = [NSString stringWithFormat:@"PrivateKey%@", keyName];
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:keychainLookup accessGroup:nil];
    NSString *privateKey = [wrapper objectForKey:(id)CFBridgingRelease(kSecValueData)];
    
    if( [privateKey isEqualToString:@""] )
    {
        // If theres no private key available, register again
        keyName = [self register:serviceId];
        
        keychainLookup = [NSString stringWithFormat:@"PrivateKey%@", keyName];
        wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:keychainLookup accessGroup:nil];
        privateKey = [wrapper objectForKey:(id)CFBridgingRelease(kSecValueData)];
    }
    
    // Create a keypair for the service
    JBRSA *rsa = [[JBRSA alloc] initWithPrivateKey:privateKey];
    
    NSString *post = [[NSString alloc] initWithFormat:@"token=%@&session_id=%d",[rsa base64EncodePrivateEncrypt:token],sessionId];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    
    NSURL *url = [NSURL URLWithString:@"https://api.passauth.net/sessions/authenticate"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *response = nil;
    NSData *urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
    
    SBJsonParser *jsonParser = [SBJsonParser new];
    NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData];
    
    if ([response statusCode] == 200)
    {
        if ((bool) [jsonData objectForKey:@"is_authenticated"])
        {
            [self alertStatus:@"The login screen should refresh any moment now." :@"Successful Login"];
            return YES;
        }
        else
        {
            [self alertStatus:@"Sorry, we weren't able to successfully authenticate you. Please try logging in again." :@"Error"];
        }
    }
    else
    {
        // Log the NSURLConnection error, if any
        if (error) NSLog(@"Login error: %@", error);
        
        NSString *message = [jsonData objectForKey:@"error[message]"];
        NSLog(@"Login error: %@", message);
        [self alertStatus: @"Sorry, something went wrong on our end. Please try logging in again." :@"Error"];
    }
    
    return NO;
}

- (bool) setServiceKeyName:(int)serviceId keyName:(NSString*)keyName
{
    FMDatabase *db = ((AppDelegate *)[UIApplication sharedApplication].delegate).db;
    return [db executeQuery:@"INSERT OR REPLACE INTO services (id, key_name) VALUES(?, ?)", [NSNumber numberWithInteger:serviceId], keyName];
}

- (NSString*) getServiceKeyName:(int)serviceId
{
    FMDatabase *db = ((AppDelegate *)[UIApplication sharedApplication].delegate).db;
    // Find if we're registered to the service
    FMResultSet *s = [db executeQuery:@"SELECT key_name FROM services WHERE id = (?) LIMIT 1", [NSNumber numberWithInteger:serviceId]];
    if ([s next]) {
        return [s stringForColumn:@"key_name"];
    } else {
        return nil;
    }
}

- (void) alertStatus:(NSString *)message :(NSString *)title
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    
    [alertView show];
}

- (void)captureSize:(ZXCapture*)capture width:(NSNumber*)width height:(NSNumber*)height {
    
}

- (void)viewDidUnload {
    [self setBtnShowNavigation:nil];
    [super viewDidUnload];
}
@end
