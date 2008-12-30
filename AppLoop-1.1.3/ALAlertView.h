//
//  AdAlertView.h
//  AppLoop
//
//  Created by Jacob Eiting on 6/7/08.
//  Copyright 2008 AppLoop. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ALAlertView : UIAlertView {
	NSString *adLink;
}

-(id)initWithAdTitle:(NSString *)title text:(NSString *)text link:(NSString *)link;

@end
