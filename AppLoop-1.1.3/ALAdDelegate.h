/*
 *  ALAnalyticsDelegate.h
 *  AppLoop
 *
 *  Created by Jacob Eiting on 6/18/08.
 *  Copyright 2008 AppLoop. All rights reserved.
 *
 */



@class ALService;

@protocol ALAdDelegate<NSObject>

@required

/*
 *  service:didGetAdWithTitle:text:link:
 *  
 *  Discussion:
 *		Invoked when the generator successfully completes an ad request.
 */
-(void)service:(ALService *)service 
	didGetAdWithTitle:(NSString *)adTitle 
				 text:(NSString *)adText 
			link:(NSString *)newLink;


/*
 *  service:failedToGetAdWithError:
 *  
 *  Discussion:
 *		Invoked when the generator fails to complete an ad request for any reason.
 */

        -(void)service:(ALService *)service 
failedToGetAdWithError:(NSError *)error;
@end

