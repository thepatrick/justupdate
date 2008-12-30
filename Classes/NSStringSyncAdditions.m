//
//  NSStringSyncAdditions.m
//  Movies
//
//  Created by Patrick Quinn-Graham on 17/03/08.
//  Copyright 2008 Patrick Quinn-Graham. All rights reserved.
//

#import "NSStringSyncAdditions.h"

@implementation NSString(SyncAdditions)

-(NSString *) urlencode
{
	CFStringRef arf = CFURLCreateStringByAddingPercentEscapes(
											NULL,
											(CFStringRef)self,
											NULL,
											(CFStringRef)@";/?:@&=+$,",
											kCFStringEncodingUTF8
	);
	NSString *returner = [NSString stringWithString:(NSString*)arf];	
	CFRelease(arf);
	return returner;
}

@end