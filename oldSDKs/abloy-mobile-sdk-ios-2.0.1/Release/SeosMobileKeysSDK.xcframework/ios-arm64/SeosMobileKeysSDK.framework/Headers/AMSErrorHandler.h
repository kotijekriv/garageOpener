/** @file */
//
//  Copyright (c) 2016 ASSA ABLOY Mobile Services. All rights reserved.
//

#import "MobileKeysErrorCodes.h"
#import "MobileKeysInternalErrorCodes.h"

@interface AMSErrorHandler : NSObject

+ (AMSErrorHandler *)handlerWithError:(NSError *)error;

- (AMSErrorHandler *)addInternalError:(MobileKeysInternalErrorCode)code withFormat:(NSString *)format, ...;

- (AMSErrorHandler *)addInternalError:(MobileKeysInternalErrorCode)code withDescription:(NSString *)description;

- (AMSErrorHandler *)addInternalError:(MobileKeysInternalErrorCode)code withDescription:(NSString *)description withNestedExternalError:(NSError *)error;

- (AMSErrorHandler *)addInternalError:(MobileKeysInternalErrorCode)code withException:(NSException *)exception;

- (AMSErrorHandler *)addNestedHTTPError:(NSError *)error isDuringSetup:(BOOL)isDuringSetup;

/**
 * Use this method to assign an error pointer with the previously stored error. If the error pointer is nil the previously
 * stored error will be logged
 * @param error will be added if it's not nil.
 */
- (void)exportError:(NSError **)error;

/**
 * Checks the NSError to see if it is an error. If it's an error, add this error to the error chain. If an error is already present, add that error as a underlying error to the one
 * specified in error.
 * @param error will be added if it's not nil.
 * @return the AmsErrorHandler itself
 */
- (AMSErrorHandler *)checkError:(NSError *)error;

- (NSError *)statisticsError;

/**
 * Use this method to log the previously saved error. This is useful if the method currently executing has no error pointer
 * parameter
 */
- (void)logError;

- (NSError *)sdkError;

- (BOOL)hasUnderlyingError:(MobileKeysInternalErrorCode)internalErrorCode;

- (BOOL)hasError;

- (NSString *)description;

@end
