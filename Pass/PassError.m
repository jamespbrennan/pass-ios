//
//  PassError.m
//  Pass
//
//  Created by James Brennan on 2013-04-17.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import "PassError.h"

NSString * const PassDomain = @"net.passauth.pass";

NSString * const PAErrorMessageKey = @"net.passauth.pass:ErrorMessageKey";
NSString * const PAErrorParameterKey = @"net.passauth.pass:ErrorParameterKey";
NSString * const PAErrorCodeKey = @"net.passauth.pass:ErrorCodeKey";

NSString * const PAEmailPasswordAuthenticationError = @"net.passauth.pass:EmailPasswordAuthenticationError";
NSString * const PAPrivateKeyAuthenticationError = @"net.passauth.pass:PrivateKeyAuthenticationError";
NSString * const PAInvalidEmail = @"net.passauth.pass:InvalidEmail";
NSString * const PAInvalidPassword = @"net.passauth.pass:InvalidEmail";
NSString * const PAFailedAuthentication = @"net.passauth.pass:FailedAuthentication";
NSString * const PAServerError = @"net.passauth.pass:ServerError";
NSString * const PADuplicateEmailError = @"net.passauth.pass:DuplicateEmailError";
