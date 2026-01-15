// MobileKeysEndpointInfo.h
// Copyright (c) 2014 ASSA ABLOY Mobile Services ( http://assaabloy.com/seos )
//
// All rights reserved.


#import <Foundation/Foundation.h>

/**
 * The different environments of Seos TSM. Ideally you (the integrator) will use `EnvironmentStaging` (integration) during development
 * and `EnvironmentProd` (production)
 */
typedef NS_ENUM(NSInteger, MobileKeysEnvironmentType) {
    EnvironmentUnknown = 15,
    EnvironmentStaging = 5,
    EnvironmentDev = 3,
    EnvironmentTest = 2,
    EnvironmentDemo = 1,
    EnvironmentProd = 0,
    EnvironmentLocal= 4,
    EnvironmentAcceptance=6
};

__attribute__(( visibility("default") ))
/**
* Class representing Information about a Seos Endpoint. Most of this information is Seos specific
* and rather technical. In addition to what gets read from Seos, this class also contains the
* current Push ID (as set through the Mobile Keys SDK) and a timestamp (`NSDate`) describing when
* the endpoint was last successfully synchronized with the Seos TSM.
*/
@interface MobileKeysEndpointInfo : NSObject

/**
 * Seos Vault ID. This uniquely identifies the local Seos Vault. This ID replaces the old endpointId, and the name change
 * is due to the fact that this ID no longer correlates to the unique endpointId provided by the Seos TSM
 * @since 5.5.0
 */
@property(nonatomic, assign) NSUInteger seosId;


/**
 * Display type of the server environment this endpoint is connected to
 */
@property(nonatomic, assign) MobileKeysEnvironmentType environmentType;

/**
 * True if this endpoint has been personalized
 */
@property(nonatomic, readonly, getter=isSetup) BOOL isSetup;

/**
 * Version of the secure element application
 */
@property(nonatomic, strong) NSString *seosAppletVersion;

/**
 * Version of the File System applet
 */
@property(nonatomic, strong) NSString *fileSystemAppletVersion;

/**
 * Version of the Tools applet
 */
@property(nonatomic, strong) NSString *toolsAppletVersion;

/**
 * Version of the JavaCard Framework (not applicable)
 */
@property(nonatomic, strong) NSString *javaCardVersion;

/**
 * Seos compilation option flags
 */
@property(nonatomic, strong) NSString *optionFlags;

/**
 * Allocated file system size.
 */
@property(nonatomic, assign) NSInteger allocatedFileSystemSize;

/**
 * How much of the file system that is currently used.
 */
@property(nonatomic, assign) NSInteger currentTopOfFileSystem;

/**
 * SNMP buffer size.
 */
@property(nonatomic, assign) NSInteger snmpBufferSize;

/**
 * Remaining space in secure element EPROM
 */
@property(nonatomic, assign) NSInteger remainingEPROMSize;

/**
 * Remaining transient object space in the secure element
 */
@property(nonatomic, assign) NSInteger remainingTransientObjectSpace;

/**
 * The hash algorithm used by Seos
 */
@property(nonatomic, assign) Byte hashAlg;

/**
 * The encryption algorithm used by Seos
 */
@property(nonatomic, assign) Byte encAlg;

/**
 * @deprecated Please disregard this property. The Seos TSM does not support push services.
 */
@property(nonatomic, strong) NSString *pushId DEPRECATED_MSG_ATTRIBUTE("Please disregard this property. The Seos TSM does not support push services");

/**
* Time of last successful communication with server
* @note since version 1.2.0
*/
@property(nonatomic, strong) NSDate *lastServerSyncDate;

/**
 * Display name of the server environment this endpoint is connected to
 */
- (NSString *)getEnvironmentName;

@end
