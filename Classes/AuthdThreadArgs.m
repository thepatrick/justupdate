//
//  AuthdThreadArgs.m
//  JustUpdate
//
//  Created by Patrick Quinn-Graham on 16/08/08.
//  Copyright 2008 Bunkerworld Publishing Ltd.. All rights reserved.
//

#import "AuthdThreadArgs.h"


@implementation AuthdThreadArgs

@synthesize username;
@synthesize password;
@synthesize selector;
@synthesize target;
@synthesize authOk;

-(void)dealloc
{
	[username release];
	[password release];
	[target release];
	[super dealloc];
}

@end
