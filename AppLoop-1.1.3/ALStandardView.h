//
//  AdView.h
//  AppLoop
//
//  Created by AppLoop on 4/12/08.
//  Copyright 2008 AppLoop. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface ALStandardView : UIView {
	UILabel* adText;
	UILabel* adTitle;
	NSString* adLink;
}

-(void)displayAdWithTitle:(NSString *)title text:(NSString *)text link:(NSString *)link;

@property (retain,nonatomic) UILabel * adText;
@property (retain,nonatomic) UILabel * adTitle;
@end
