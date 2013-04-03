//
//  LoginViewController.m
//  Pass
//
//  Created by James Brennan on 2013-03-27.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import "LoginViewController.h"
#import "SBJson.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) alertStatus:(NSString *)msg :(NSString *)title
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    
    [alertView show];
}

- (IBAction) loginClicked:(id)sender {
    [self doLogin:[_txtEmail text] withPassword:[_txtPassword text]];
}

- (IBAction) createAccountClicked:(id)sender {
    [self doRegistration:[_txtEmail text] withPassword:[_txtPassword text]];
}

- (IBAction) backgroundClicked:(id)sender {
    [_txtEmail resignFirstResponder];
    [_txtPassword resignFirstResponder];
}

- (void) doLogin:(NSString*)email withPassword:(NSString*)password {
    NSMutableURLRequest *request = [self prepareLoginRequest:email withPassword:password];
    
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *response = nil;
    NSData *urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    
    NSLog(@"Response code: %d", [response statusCode]);
    
    if ([response statusCode] == 200)
    {
        NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
        NSLog(@"Response ==> %@", responseData);
        
        SBJsonParser *jsonParser = [SBJsonParser new];
        NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData];
        NSLog(@"%@",jsonData);
        NSInteger success = [(NSNumber *) [jsonData objectForKey:@"success"] integerValue];
        NSLog(@"%d",success);
        
        NSLog(@"Login SUCCESS");
        [self alertStatus:@"Logged in Successfully." :@"Login Success!"];
        
    }
    else if (error.code == -1012) // 401 Unauthorized
    {
        if (error) NSLog(@"Error: %@", error);
        [self alertStatus:@"Wrong email and password combination." :@"Login Failed"];
    }
    else
    {
        if (error) NSLog(@"Error: %@", error);
        [self alertStatus:@"Something has gone wrong on our end, please try to log in again in a few minutes." :@"Sorry, something went wrong."];
    }
}

- (void) doRegistration:(NSString*)email withPassword:(NSString*)password {
    // Post to users#create to make a user account
    NSMutableURLRequest *request = [self prepareRegistrationRequest:email withPassword:password];
    
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *response = nil;
    NSData *urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    
    NSLog(@"Response code: %d", [response statusCode]);
    
    if ([response statusCode] == 200)
    {
        NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
        
        NSLog(@"Response ==> %@", responseData);
        
        SBJsonParser *jsonParser = [SBJsonParser new];
        NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData];

        NSLog(@"%@",jsonData);
        NSLog(@"Registered successfully");
    }
    else
    {
        if (error) NSLog(@"Error: %@", error);
        [self alertStatus:@"Something has gone wrong on our end, please try to log in again in a few minutes." :@"Sorry, something went wrong."];
        return;
    }
    
    // Post to devices#create to create a device account 
    request = [self prepareLoginRequest:email withPassword:password];
    
    error = [[NSError alloc] init];
    response = nil;
    urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    
    NSLog(@"Login response code: %d", [response statusCode]);
    
    if ([response statusCode] == 200)
    {
        NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
        
        NSLog(@"Login response ==> %@", responseData);
        
        SBJsonParser *jsonParser = [SBJsonParser new];
        NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData];
        
        NSLog(@"%@",jsonData);
        NSString *token = (NSString *) [jsonData objectForKey:@"token"];
        [self storeToken:token];
        
        NSLog(@"Token %@",token);
        NSLog(@"Login SUCCESS");
    }
    else
    {
        if (error) NSLog(@"Login error: %@", error);
        [self alertStatus:@"Something has gone wrong on our end, please try to log in again in a few minutes." :@"Sorry, something went wrong."];
    }
}

- (NSMutableURLRequest*) prepareLoginRequest:(NSString*)email withPassword:(NSString*)password {
    return [self prepareRequest:@"http://api.pass-server.localhost:3000/devices" withEmail:email withPassword:password];
}

- (NSMutableURLRequest*) prepareRegistrationRequest:(NSString*)email withPassword:(NSString*)password {
    return [self prepareRequest:@"http://api.pass-server.localhost:3000/users" withEmail:email withPassword:password];
}

- (NSMutableURLRequest*) prepareRequest:(NSString*)address withEmail:(NSString*)email withPassword:(NSString*)password {
    @try {
        if ([email isEqualToString:@""] || [password isEqualToString:@""] )
        {
            [self alertStatus:@"Please enter both email and password" :@"Hey there!"];
        }
        else
        {
            // URL encode the email and password
            email = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)email, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
            password = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)password, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
            
            NSURL *url=[NSURL URLWithString:address];
            
            NSString *post = [[NSString alloc] initWithFormat:@"email=%@&password=%@",email,password];
            NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
            NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
            
            NSLog(@"PostData: %@",post);
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setURL:url];
            [request setHTTPMethod:@"POST"];
            [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:postData];
            
            return request;
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        [self alertStatus:@"Something has gone wrong on our end, please try to log in again in a few minutes." :@"Sorry, something went wrong."];
    }
}

- (void) storeToken:(NSString*)token {
    
}
@end
