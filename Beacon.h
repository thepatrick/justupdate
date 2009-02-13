//
//  Beacon.h
//  PinchMedia
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface Beacon : NSObject <CLLocationManagerDelegate> {
	NSString			*applicationCode;
	BOOL				beaconStarted;
	BOOL				uploading;
	BOOL				pathFlag;
	BOOL				useWiFi;
	BOOL				useCoreLocation;
	CLLocationManager	*locationManager;
	NSURLConnection		*connection;
	NSMutableData		*receivedData;
}


+ (id)initAndStartBeaconWithApplicationCode:(NSString *)theApplicationCode useCoreLocation:(BOOL)coreLocation useOnlyWiFi:(BOOL)wifiState;
+ (id)shared;
- (void)startSubBeaconWithName:(NSString *)beaconName timeSession:(BOOL)trackSession;
- (void)endSubBeaconWithName:(NSString *)beaconName;
- (void)startBeacon;
- (void)endBeacon;
- (void)setBeaconLocation:(CLLocation *)newLocation;
- (NSDictionary *)getCurrentRunningBeacon;


@end
