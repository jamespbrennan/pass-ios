//
//  PassTests.m
//  PassTests
//
//  Created by James Brennan on 2013-03-27.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import "PassTests.h"

@implementation PassTests

Pass *pass;

- (void)setUp
{
    [super setUp];
    self.pass = [Pass sharedInstance];
}

- (void)tearDown
{
    [super tearDown];
}

//+ (Pass *)sharedInstance;
- (void) testSingleton {
    STAssertEqualObjects(self.pass, [Pass sharedInstance], @"Pass singletons should be equal");
}

//- (bool)registerUser:(NSString*)email password:(NSString*)password error:(NSError**)error;
- (void) testValidateRegisterUserEmail {
    NSError * error = nil;
    NSDictionary *userInfo = [NSDictionary alloc];
    
    STAssertFalse([self.pass registerUser:@"blah" password:@"password" error:&error], @"Regsiter user should fail because of bad email format");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAInvalidEmailMessage, @"Invalid email should return accurate error.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], @"email", @"Error should be related to the email paramater");
    
    error = nil;
    
    STAssertFalse([self.pass registerUser:@"" password:@"password" error:&error], @"Regsiter user should fail because of blank email");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAInvalidEmailMessage, @"Invalid email should return accurate error.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], @"email", @"Error should be related to the email paramater");
}

- (void) testNonUniqueRegisterUserEmail {
    NSError * error = nil;
    NSDictionary *userInfo = [NSDictionary alloc];
    NSString *email = [NSString stringWithFormat:@"ios-registeruser-%.0f@unit.test", [[NSDate date] timeIntervalSince1970]];
    NSString *password = @"password";

    STAssertTrue([self.pass registerUser:email password:password error:&error], @"Regsiter user should fail because of incorrect credentials");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], nil, @"Not error should be returned.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], nil, @"Error should be related to the email paramater");
    
    error = nil;
    
    STAssertFalse([self.pass registerUser:email password:password error:&error], @"Regsiter user should fail because of incorrect credentials");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], nil, @"Not error should be returned.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], nil, @"Error should be related to the email paramater");
}

- (void) testValidateRegisterUserPassword {
    NSError * error = [NSError alloc];
    NSDictionary *userInfo = [NSDictionary alloc];
    NSString *email = [NSString stringWithFormat:@"ios-registeruser-%.0f@unit.test", [[NSDate date] timeIntervalSince1970]];
    NSString *password = nil;
    
    STAssertFalse([self.pass registerUser:email password:password error:&error], @"Regsiter user should fail because of blank password");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAInvalidPasswordMessage, @"Invalid password should return accurate error.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], @"password", @"Error should be related to the email paramater");
    
    error = nil;
    password = @"";
    
    STAssertFalse([self.pass registerUser:email password:password error:&error], @"Regsiter user should fail because of blank password");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAInvalidPasswordMessage, @"Invalid password should return accurate error.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], @"password", @"Error should be related to the email paramater");
    
    error = nil;
    password = @"p";
    
    STAssertTrue([self.pass registerUser:email password:password error:&error], @"Regsiter user should be successful");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], nil, @"Error should be blank");
    
    // Clean up
    [pass deleteUser:email password:password error:nil];
    
    error = nil;
    email = [NSString stringWithFormat:@"ios-registeruser2-%.0f@unit.test", [[NSDate date] timeIntervalSince1970]];
    password = @"password";
    
    STAssertTrue([self.pass registerUser:email password:password error:&error], @"Regsiter user should be successful");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], nil, @"Error should be blank");
    
    // Clean up
    [pass deleteUser:email password:password error:nil];
}

//- (bool)login:(NSString*)email password:(NSString*)password error:(NSError**)error;
- (void) testValidateLoginEmail {
    NSError * error = nil;
    NSDictionary *userInfo = [NSDictionary alloc];
    
    STAssertFalse([self.pass login:@"blah" password:@"password" error:&error], @"Login should fail because of bad email format");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAInvalidEmailMessage, @"Invalid email should return accurate error.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], @"email", @"Error should be related to the email paramater");
    
    error = nil;
    
    STAssertFalse([self.pass login:@"" password:@"password" error:&error], @"Login should fail because of blank email");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAInvalidEmailMessage, @"Invalid email should return accurate error.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], @"email", @"Error should be related to the email paramater");
}

- (void) testValidateLoginPassword {
    NSError * error = [NSError alloc];
    NSDictionary *userInfo = [NSDictionary alloc];
    NSString *email = [NSString stringWithFormat:@"ios-registeruser-%.0f@unit.test", [[NSDate date] timeIntervalSince1970]];
    
    STAssertFalse([self.pass login:email password:@"" error:&error], @"Login should fail because of blank password");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAInvalidPasswordMessage, @"Invalid email should return accurate error.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], @"password", @"Error should be related to the email paramater");
    
    error = nil;
    
    STAssertFalse([self.pass login:email password:@"notarealpassword" error:&error], @"Login should fail because of incorrect credentials");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAEmailPasswordAuthenticationErrorMessage, @"Invalid email should return accurate error.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], nil, @"Error should be related to the email paramater");
    
    error = nil;
    
    STAssertFalse([self.pass login:@"foo@bar.com" password:@"p" error:&error], @"Login should fail because of incorrect credentials");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAEmailPasswordAuthenticationErrorMessage, @"Invalid email should return accurate error.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], nil, @"Error should be related to the email paramater");
}
//- (void)setDeviceAPIToken:(NSString*)token;
//- (NSString *)getAPIToken;
- (void) testSetGetDeviceAPI {
    NSString *token = @"dbb051583493abb72b764c70cc415a02";
    [self.pass setAPIToken:token];
    STAssertEqualObjects([self.pass getAPIToken], token, @"Get token should return the proper string");
}
//- (bool)setServicePrivateKey:(int)serviceId privateKey:(NSString*)privateKey;
//- (NSString *)getServicePrivateKey:(int)serviceId;
- (void) testSetGetServicePrivateKey {
    int serviceId = 5;
    NSString *privateKey = @"0ca85b1a4ecc79264cd1c2de145fc53b54b6b686e0a0ae72d0db7a6c59372d28";
    
    STAssertTrue([self.pass setServicePrivateKey:serviceId privateKey:privateKey], @"Set service private key should be successful");
    STAssertEqualObjects([self.pass getServicePrivateKey:serviceId], privateKey, @"Get service private key should return the proper key");
}
//- (NSString *)getDeviceModel;
- (void) testGetDeviceModel {
    STAssertNotNil([self.pass getDeviceModel], [self.pass getDeviceModel]);
}
//- (NSString *)URLEncodedString:(NSString *)string;
- (void) testURLEncodedString {
    NSString *test = [self.pass URLEncodedString:@"TestString!*'();:@&=+$,/?%#[]TestString"];
    
    STAssertTrue([test rangeOfString:@"!"].location == NSNotFound, @"Should not contain !");
    STAssertTrue([test rangeOfString:@"*"].location == NSNotFound, @"Should not contain *");
    STAssertTrue([test rangeOfString:@"'"].location == NSNotFound, @"Should not contain '");
    STAssertTrue([test rangeOfString:@"("].location == NSNotFound, @"Should not contain (");
    STAssertTrue([test rangeOfString:@")"].location == NSNotFound, @"Should not contain )");
    STAssertTrue([test rangeOfString:@";"].location == NSNotFound, @"Should not contain ;");
    STAssertTrue([test rangeOfString:@":"].location == NSNotFound, @"Should not contain :");
    STAssertTrue([test rangeOfString:@"@"].location == NSNotFound, @"Should not contain @");
    STAssertTrue([test rangeOfString:@"&"].location == NSNotFound, @"Should not contain &");
    STAssertTrue([test rangeOfString:@"="].location == NSNotFound, @"Should not contain =");
    STAssertTrue([test rangeOfString:@"+"].location == NSNotFound, @"Should not contain +");
    STAssertTrue([test rangeOfString:@"$"].location == NSNotFound, @"Should not contain $");
    STAssertTrue([test rangeOfString:@","].location == NSNotFound, @"Should not contain ,");
    STAssertTrue([test rangeOfString:@"/"].location == NSNotFound, @"Should not contain /");
    STAssertTrue([test rangeOfString:@"?"].location == NSNotFound, @"Should not contain ?");
    STAssertTrue([test rangeOfString:@"%25"].location != NSNotFound, @"Should not contain %");
    STAssertTrue([test rangeOfString:@"#"].location == NSNotFound, @"Should not contain #");
    STAssertTrue([test rangeOfString:@"["].location == NSNotFound, @"Should not contain [");
    STAssertTrue([test rangeOfString:@"]"].location == NSNotFound, @"Should not contain ]");
}
//- (void)firstRunCleanUp;
- (void) testFirstRunCleanUp {
    NSString *token = @"bar";
    [pass setAPIToken:token];
    [pass setServicePrivateKey:5 privateKey:@"foo"];
    
    [pass firstRunCleanUp];
    
    STAssertFalse([[pass getAPIToken] isEqualToString:token], @"First run cleanup should clear the token");
    STAssertNil([pass getServicePrivateKey:5], @"First run cleanup should clear service private key");
}
//- (bool)validateEmail:(id *)ioValue error:(NSError **)outError;
- (void) testValidateEmailInvalid {
    NSError *error = nil;
    NSDictionary *userInfo = nil;
    NSString *test = nil;
    
    STAssertFalse([self.pass validateEmail:&test error:&error], @"Validate email should fail for non email");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAInvalidEmailMessage, @"Invalid email should return accurate error.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], @"email", @"Error should be related to the email paramater");
    
    error = nil;
    userInfo = nil;
    test = @"foo";
    STAssertFalse([self.pass validateEmail:&test error:&error], @"Validate email should fail for non email");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAInvalidEmailMessage, @"Invalid email should return accurate error.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], @"email", @"Error should be related to the email paramater");
    
    error = nil;
    userInfo = nil;
    
    test = @"foo@";
    STAssertFalse([self.pass validateEmail:&test error:&error], @"Validate email should fail for non email");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAInvalidEmailMessage, @"Invalid email should return accurate error.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], @"email", @"Error should be related to the email paramater");
    
    error = nil;
    userInfo = nil;
    
    test = @"foo@bar";
    STAssertFalse([self.pass validateEmail:&test error:&error], @"Validate email should fail for non email");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAInvalidEmailMessage, @"Invalid email should return accurate error.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], @"email", @"Error should be related to the email paramater");
    
    error = nil;
    userInfo = nil;
    
}
- (void) testValidateEmailValid {
    NSError *error = nil;
    NSDictionary *userInfo = nil;
    NSString *test = nil;
    
    test = @"foo@bar.baz";
    STAssertTrue([self.pass validateEmail:&test error:&error], @"Validate email should pass for valid email");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], nil, @"Invalid email should return accurate error.");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], nil, @"Error should be related to the email paramater");
}
//- (bool)validatePassword:(id *)ioValue error:(NSError **)outError;
- (void) testValidatePasswordInvalid {
    NSError *error = nil;
    NSDictionary *userInfo = nil;
    NSString *test = nil;
    
    STAssertFalse([self.pass validatePassword:&test error:&error], @"Validate password should fail for invalid password");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAInvalidPasswordMessage, @"Invalid password should return accurate error");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], @"password", @"Error should be related to the password paramater");
    
    error = nil;
    userInfo = nil;
    
    test = @"";
    STAssertFalse([self.pass validatePassword:&test error:&error], @"Validate password should fail for invalid password");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAInvalidPasswordMessage, @"Invalid password should return accurate error");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], @"password", @"Error should be related to the password paramater");
}
- (void) testValidatePasswordValid {
    NSError *error = nil;
    NSDictionary *userInfo = nil;
    NSString *test = nil;
    
    test = @"foo";
    STAssertTrue([self.pass validatePassword:&test error:&error], @"Validate password should pass for valid password");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], nil, @"");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], nil, @"");
    
    test = @"f";
    STAssertTrue([self.pass validatePassword:&test error:&error], @"Validate password should pass for valid password");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], nil, @"");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], nil, @"");
    
    test = @"1";
    STAssertTrue([self.pass validatePassword:&test error:&error], @"Validate password should pass for valid password");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], nil, @"");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], nil, @"");
    
    test = @"*";
    STAssertTrue([self.pass validatePassword:&test error:&error], @"Validate password should pass for valid password");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], nil, @"");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], nil, @"");
    
    test = @"1 2 3";
    STAssertTrue([self.pass validatePassword:&test error:&error], @"Validate password should pass for valid password");
    userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], nil, @"");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], nil, @"");
}
//- (NSError *)createErrorWithMessage:(NSString *)userMessage parameter:(NSString *)parameter errorCode:(NSString *)errorCode devErrorMessage:(NSString *)devMessage;
- (void) testCreateErrorWithMessage {
    NSError *error = [self.pass createErrorWithMessage:PAInvalidPasswordMessage parameter:@"password" errorCode:PAInvalidPassword devErrorMessage:@"Password must not be blank."];
    NSDictionary *userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:NSLocalizedDescriptionKey], PAInvalidPasswordMessage, @"Error should have proper message");
    STAssertEqualObjects([userInfo valueForKey:PAErrorParameterKey], @"password", PAInvalidPassword);
}

@end
