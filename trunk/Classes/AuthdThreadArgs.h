//
//  AuthdThreadArgs.h
//  JustUpdate
//
//  Created by Patrick Quinn-Graham on 16/08/08.
//  Copyright 2008 Bunkerworld Publishing Ltd.. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AuthdThreadArgs : NSObject {

	NSString *username;
	NSString *password;
	SEL selector;
	id target;
	
	BOOL authOk;
		
}

@property (copy, nonatomic) NSString *username;
@property (copy, nonatomic) NSString *password;
@property (assign, nonatomic) SEL selector;
@property (retain, nonatomic) id target;
@property (assign, nonatomic) BOOL authOk;

@end
