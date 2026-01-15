// AMSEventReporter.h
// Copyright (c) 2017 ASSA ABLOY Mobile Services ( http://assaabloy.com/seos )
// 
// All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AMSMacros.h"

@class AMSEvent;
@class AMSThunderHoofClient;
@class AMSUserDefaults;
@class AMSClock;
@class AMSMKDevice;

@interface AMSEventReporter : NSObject

- (instancetype)initWitThunderHoofClient:(AMSThunderHoofClient *)thunderHoofClient clock:(AMSClock *)clock device:(AMSMKDevice *)device;

- (void)logEvent:(AMSEvent *)event;

- (void)startTimerForEvents:(NSArray<NSString *> *)event;

- (void)appendProperties:(NSDictionary<NSString *, NSObject *> *)properties toEvent:(AMSEvent *)event;

- (void)dispatchGlobalProperties:(NSDictionary<NSString *, NSObject *> *)properties;

- (void)dispatchTimerForEvent:(NSString *)event;

- /* abstract */ (void)dispatchEvent:(AMSEvent *)event AMS_DECLARE_ABSTRACT("dispatchEvent: is abstract");
@end
