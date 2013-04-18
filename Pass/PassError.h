//
//  PassError.h
//  Pass
//
//  Created by James Brennan on 2013-04-17.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const PassDomain;

typedef enum PAErrorCode {
    PAInvalidParameterError = 50,
} STPErrorCode;

FOUNDATION_EXPORT NSString * const PAErrorParameterKey;

FOUNDATION_EXPORT NSString * const PAErrorMessageKey;

FOUNDATION_EXPORT NSString * const PAErrorCodeKey;


FOUNDATION_EXPORT NSString * const PAEmailPasswordAuthenticationError;
FOUNDATION_EXPORT NSString * const PAPrivateKeyAuthenticationError;
FOUNDATION_EXPORT NSString * const PAInvalidEmail;
FOUNDATION_EXPORT NSString * const PAInvalidPassword;

#define PAEmailPasswordAuthenticationErrorMessage NSLocalizedString(@"Invalid email and password combination.", @"Error when the username and password combination is not valid")
#define PAPrivateKeyAuthenticationErrorMessage NSLocalizedString(@"Sorry, we were unable to successfully authenticate you. Please try loggin in again.", @"Error when private key authentication is unsuccessful")
#define PAInvalidEmailMessage NSLocalizedString(@"Sorry, you must provide a valid email address.", @"Error when an email address provided is not a valid email address")
#define PAInvalidPasswordMessage NSLocalizedString(@"Sorry, you must provide a password.", @"Error when no password is provided")
