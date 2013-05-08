//
//  PassTests.h
//  PassTests
//
//  Created by James Brennan on 2013-03-27.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "Pass.h"
#import "PassError.h"

@interface PassTests : SenTestCase
@property (unsafe_unretained, nonatomic) Pass *pass;

- (void) testSingleton;
- (void) testValidateRegisterUserEmail;
- (void) testNonUniqueRegisterUserEmail;
- (void) testValidateRegisterUserPassword;
- (void) testValidateLoginEmail;
- (void) testValidateLoginPassword;
- (void) testSetGetDeviceAPI;
- (void) testSetGetServicePrivateKey;
- (void) testGetDeviceModel;
- (void) testURLEncodedString;
- (void) testFirstRunCleanUp;
- (void) testValidateEmailInvalid;
- (void) testValidateEmailValid;
- (void) testValidatePasswordInvalid;
- (void) testValidatePasswordValid;
- (void) testCreateErrorWithMessage;
@end
