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

- (IBAction)loginClicked:(id)sender {
    @try {
        
        if ([[_txtEmail text] isEqualToString:@""] || [[_txtPassword text] isEqualToString:@""] )
        {
            [self alertStatus:@"Please enter both email and password" :@"Login Failed!"];
        }
        else
        {
            // Post to devices#create
            NSURL *url=[NSURL URLWithString:@"http://api.pass-server.dev/devices"];
            
            NSString *post =[[NSString alloc] initWithFormat:@"email=%@&password=%@",[_txtEmail text],[_txtPassword text]];
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
            
            NSError *error = [[NSError alloc] init];
            NSHTTPURLResponse *response = nil;
            NSData *urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

            
            NSLog(@"Response code: %d", [response statusCode]);
            

            if ([response statusCode] == 200)
            {
                NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
                NSLog(@"Response ==> %@", responseData);
                
                SBJsonParser *jsonParser = [SBJsonParser new];
                NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
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
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        [self alertStatus:@"Something has gone wrong on our end, please try to log in again in a few minutes." :@"Sorry, something went wrong."];
    }
}

- (IBAction)createAccountClicked:(id)sender {
}

- (IBAction)backgroundClicked:(id)sender {
    [_txtEmail resignFirstResponder];
    [_txtPassword resignFirstResponder];
}
@end
