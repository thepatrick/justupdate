//
//  ALService.h
//  AppLoop
//
//  Created by Jacob Eiting on 7/1/08.
//  Copyright 2008 AppLoop. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ALAdDelegate.h"

#import <CoreLocation/CoreLocation.h>


enum {
	AL_HOST_UNREACHABLE = 0,
	AL_INVALID_RESPONSE,
	AL_UNKOWN_ERROR,
	AL_AD_REQUEST_IN_PROGRESS,
	AL_AD_REQUEST_TOO_RAPID
};

@interface ALService : NSObject <CLLocationManagerDelegate> {
	id<ALAdDelegate> adDelegate;
	
	CLLocationManager *locationManager;
	CLLocation *location;
	
	BOOL trackLocation;
	BOOL analyzing;
	BOOL requestingAd;
	BOOL locFailed;
	
	NSString *session;
	
	NSTimer *geoTimer;
	
	NSCondition *locationUpdated;
	
	NSDate *locationUpdateTime;
	NSDate *lastAdRequest;
}

+(void)setApplicationKey:(NSString *)string applicationSecret:(NSString *)secret;
+(ALService *)sharedService;

-(void)startAnalysisUsingLocation:(BOOL)useLocation;
-(void)stopAnalysis;

-(void)logAction:(NSString *)action;

-(void)requestAdUsingLocation:(BOOL)usingLocation; 

@property(retain, nonatomic) id adDelegate;


@end
