/*
 * Copyright (c) 2008 Patrick Quinn-Graham
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
 */

#import "OAuthConsumer.h"
#import "JustUpdateAppDelegate.h"
#import "AuthdThreadArgs.h"
#import "NSStringSyncAdditions.h"
#import "JSON.h"
#import "Beacon.h"

// NB: JustUpdateTwitterDefines.h provides:
// #define JUKey @"..."
// #define JUSecret @"..."
// You'll need obtain these for yourself by registering a new app on twitter.com
// You should NOT commit JustUpdateTwitterDefines.h to git.
#import "JustUpdateTwitterDefines.h"


@implementation JustUpdateAppDelegate

@synthesize window;
@synthesize replyPeople;
@synthesize replyPrefix;
@synthesize scaler;

-(void)applicationDidFinishLaunching:(UIApplication *)application 
{	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];

	NSInteger currentBuild = [(NSString*)[[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"] integerValue];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];		
	NSMutableDictionary *dd = [NSMutableDictionary dictionaryWithObject:@"" forKey:@"JUUsername"];
	[dd setValue:@"" forKey:@"JUPassword"];
	[dd setValue:@"NO" forKey:@"JUConfirmedAnalytics"];
	[dd setValue:@"NO" forKey:@"JUDisableAnalytics"];
	[dd setValue:[NSNumber numberWithInteger:currentBuild] forKey:@"currentbuild"];
	[defaults registerDefaults:dd];

	charactersRemaining.enabled = false;
	
	//newTweetView.frame = [[UIScreen mainScreen] applicationFrame];
	
	
	[self.view addSubview:newTweetView]; 
	[self.window addSubview:self.view];
	
	NSString *lastTweetText = [[NSUserDefaults standardUserDefaults] stringForKey:@"JUSavedTweet"];
	if(lastTweetText) {
		newTweet.text = lastTweetText;		
	} else {
		newTweet.text = @"";
	}
	
	newTweet.delegate = self;
	
	if(![defaults boolForKey:@"JUConfirmedAnalytics"]) {
		UIAlertView *uav = [[UIAlertView alloc] initWithTitle:@"Anonymous Statistics" 
													  message:@"JustUpdate would like to collect anonymous usage statistics during operation.\n\n At no time does any of this information contain the content of your tweets, your username, your location, or any other identifying information.\n\nVisit the website for full details." 
													 delegate:self 
											cancelButtonTitle:@"Disable" 
											otherButtonTitles:@"OK", nil];
		[uav show];
		[uav autorelease];
	}
	
	disableAnalytics  = [[NSUserDefaults standardUserDefaults] boolForKey:@"JUDisableAnalytics"];
	if(!disableAnalytics) {
		NSString *applicationCode = @"e20c4f9c194bea9049b6daf7d649c261";
		[Beacon initAndStartBeaconWithApplicationCode:applicationCode useCoreLocation:NO useOnlyWiFi:NO];
	}
	
	
	BOOL doSignin = YES;
	
	OAToken *accessToken = self.accessToken;
	if(accessToken) {
		doSignin = NO;
	} else {
		OAToken *requestToken = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:@"auth_request"
																					   prefix:@"twitter"];
		if(requestToken) {
			[requestToken release];
			[self getAccessToken];
			doSignin = NO;
		}
	}
	
	if(doSignin) {
		[self showSignin];
	} else {
		self.title = [defaults valueForKey:@"JUUsername"];
		[newTweet becomeFirstResponder];
	}
	
	self.replyPeople = [NSArray array];
	
	[window makeKeyAndVisible];
	
	NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleShortVersionString"];
	
	if(![[defaults valueForKey:@"JUPassword"] isEqualToString:@""]) {
		UIAlertView *uav = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Welcome to JustUpdate %@", currentVersion] 
													  message:@"Thank you for upgrading.\n\nThis version of JustUpdate uses the new OAuth API for twitter, which means it is no longer necessary to enter your password in JustUpdate.\n\nUnfortunately this also means you will need to sign-in again. Just tap on the Sign In using Twitter button to begin." 
													 delegate:nil 
											cancelButtonTitle:@"Dismiss" 
											otherButtonTitles:nil];
		[uav show];
		[uav autorelease];
		[defaults setValue:@"" forKey:@"JUPassword"];
	} else {
		// A future release can use to easily display a "Thanks for upgrading!" or some such based on the previous build number
		//if(currentBuild > [defaults integerForKey:@"currentbuild"]) {
		//	UIAlertView *uav = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Welcome to JustUpdate %@", currentVersion] 
		//												  message:@"Thank you for upgrading." 
		//												 delegate:nil 
		//										cancelButtonTitle:@"Dismiss" 
		//										otherButtonTitles:nil];
		//	[uav show];
		//	[uav autorelease];
		//}
	}
	
	currentStatusBarHeight = application.statusBarFrame.size.height;
	[self willAnimateFirstHalfOfRotationToInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation] duration:0];
	//[[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"]

	[defaults setInteger:currentBuild forKey:@"currentbuild"];
}

-(void)application:(UIApplication *)application didChangeStatusBarFrame:(CGRect)newStatusBarFrame {
	if(application.statusBarFrame.size.height < 100) {
		currentStatusBarHeight = application.statusBarFrame.size.height;
		[self willAnimateFirstHalfOfRotationToInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation] duration:0];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if(replyPickerOverlayVisible) return NO;
	return YES;
}

- (void)willAnimateFirstHalfOfRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	UIApplication *application = [UIApplication sharedApplication];
	if(application.statusBarFrame.size.height < 100) {
		currentStatusBarHeight = application.statusBarFrame.size.height;
	}
	
	CGRect f = scaler.frame;
	CGRect textFrame = newTweet.frame;
	CGRect navFrame = navigationBar.frame;
	CGRect toolbarFrame = postBar.frame;
	
	CGRect signinToolbarFrame = signInNavigationBar.frame;
	CGRect signinBoxesFrame = signinBoxes.frame;
	
	CGRect replyPickerOverlayFrame = replyPickerOverlay.frame;
	CGRect replyPickerPersonFrame = replyPickerPerson.frame;
	CGRect replyPickerTitleBackgroundFrame = replyPickerTitleBackground.frame;
	CGRect replyPickerTitleFrame = replyPickerTitle.frame;
	
	CGRect postingTweetFrame = postingTweet.frame;
	
	NSLog(@"offset before %f", replyPickerTitleBackgroundFrame.origin.y );
	
	CGFloat keyboardSize = 0;
	CGFloat keyboardOffsetY = 0;
	CGFloat screenWidth = 0;
	
	if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
		f.size.height = 160;
		textFrame.origin.y = 52;
		textFrame.size.height = 74;
		navFrame.size.height = 32;
		toolbarFrame.size.height = 32;
		signInNavigationItem.prompt = @"";
		signinToolbarFrame.size.height = 32;
		replyPickerOverlayFrame.origin.y = -58;
		replyPickerTitleBackgroundFrame.origin.y = -10;
		replyPickerTitleFrame.origin.y = 41;
		
		keyboardSize = 160;
		keyboardOffsetY = 140;
		screenWidth = 480;
	} else {
		
		f.size.height = 282 - currentStatusBarHeight;
		textFrame.origin.y = 64;
		textFrame.size.height = 174 - currentStatusBarHeight;		
		navFrame.size.height = 44;	
		toolbarFrame.size.height = 44;
		signInNavigationItem.prompt = @"JustUpdate";
		signinToolbarFrame.size.height = 74;
		replyPickerOverlayFrame.origin.y = -70;
		replyPickerTitleBackgroundFrame.origin.y = 86;
		replyPickerTitleFrame.origin.y = 137;
		
		keyboardSize = 216;
		keyboardOffsetY = 264 - currentStatusBarHeight;
		screenWidth = 320;
	}
	
	replyPickerPersonFrame.size.width = screenWidth;
	replyPickerPersonFrame.size.height = keyboardSize;
	replyPickerPersonFrame.origin.y = keyboardOffsetY;
	postingTweetFrame.size.width = screenWidth;
	postingTweetFrame.size.height = keyboardSize;
	postingTweetFrame.origin.y = keyboardOffsetY;
	
	NSLog(@"offset after %f", replyPickerTitleBackgroundFrame.origin.y );

	
	toolbarFrame.origin.y = textFrame.origin.y + textFrame.size.height;
	signinBoxesFrame.origin.y = signinToolbarFrame.size.height;
	
	scaler.frame = f;
	newTweet.frame = textFrame;
	navigationBar.frame = navFrame;
	postBar.frame = toolbarFrame;
	signInNavigationBar.frame = signinToolbarFrame;
	signinBoxes.frame = signinBoxesFrame;
	
	replyPickerOverlay.frame = replyPickerOverlayFrame;
	replyPickerPerson.frame = replyPickerPersonFrame;
	replyPickerTitleBackground.frame = replyPickerTitleBackgroundFrame;
	replyPickerTitle.frame = replyPickerTitleFrame;
	
	postingTweet.frame = postingTweetFrame;
	
	NSLog(@"willAnimateSecondHalfOfRotationFromInterfaceOrientation");
	
}

-(NSDictionary*)dictionaryFromQueryString:(NSString*)query {
	
	NSArray *all = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *qsDict = [NSMutableDictionary dictionaryWithCapacity:[all count]];
	
	for(NSString *qsElement in all) {
		NSArray *qsElements = [qsElement componentsSeparatedByString:@"="];
		if([qsElements count] == 2) {
			NSString *key = [qsElements objectAtIndex:0];
			NSString *value = [[qsElements objectAtIndex:1] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
			NSString *valueValue = (NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)value, CFSTR(""), kCFStringEncodingUTF8);
			
			[qsDict setObject:valueValue forKey:key];
			[valueValue release];
		}
	}
	return qsDict;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
	
	BOOL handledURL = NO;
		
	if([[url host] isEqualToString:@"tweet"]) {
		NSDictionary *d = [self dictionaryFromQueryString:[url query]];
		NSString *msg = [d objectForKey:@"msg"];
		if(msg) {
			newTweet.text = [newTweet.text stringByAppendingFormat:msg];
			handledURL = YES;
		}
	} else {
		// it's probably an auth 
		NSLog(@"Launched with: %@", url);
	}
	
	return handledURL;
}

-(CGRect)orientateFrame:(CGRect)frame {
	if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
		return CGRectMake(frame.origin.y, frame.origin.x, frame.size.height, frame.size.width);
	}
	return frame;
}

-(void)showSignin 
{
	[self textViewDidChange:newTweet];
	
	CGRect baseFrame = [self orientateFrame:self.view.frame];
	
	baseFrame.origin.y = baseFrame.size.height;
	signinView.frame = baseFrame;

	[self.view addSubview:signinView];

	[UIView beginAnimations:@"showSignIn" context:nil];
	
	baseFrame = [self orientateFrame:self.view.frame];
	baseFrame.origin.y = 0;
	signinView.frame = baseFrame;
	
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationStopped:afterFinishing:withContext:)];
	[UIView commitAnimations];
	
}

-(void)hideSignin
{
	[UIView beginAnimations:@"hideSignIn" context:nil];
	
	CGRect baseFrame = [[UIScreen mainScreen] applicationFrame];
	baseFrame.origin.y = baseFrame.origin.y + baseFrame.size.height;
	signinView.frame = baseFrame;
	
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationStopped:afterFinishing:withContext:)];
	[UIView commitAnimations];
}

-(void)animationStopped:(NSString*)animationID afterFinishing:(BOOL)finished withContext:(void*)context
{
	//NSLog(@"Ended animation %@", animationID);
	if(animationID == @"hideSignIn") {
		[signinView retain];
		[signinView removeFromSuperview];
	}
	if(animationID == @"hideAboutScreen") {
		[self dismissAboutScreenDone];
	}
	if(animationID == @"hideAboutCreditsView") {
		[aboutCreditsView removeFromSuperview];
	}
}


- (void)applicationWillTerminate:(UIApplication *)application
{
	
	[[NSUserDefaults standardUserDefaults] setValue:newTweet.text forKey:@"JUSavedTweet"];
	if(!disableAnalytics) [[Beacon shared] endBeacon];
}

-(void)dealloc {
	[window release];
	[replyPeople release];
	[replyPrefix release];
	[consumer release];
	[super dealloc];
}

#pragma mark -
#pragma mark Text View Delegate Methods

-(void)textViewDidChange:(UITextView *)textView 
{
	charactersRemaining.title = [NSString stringWithFormat:@"%d remaining", (140 - [newTweet.text length])];
	postTweetItem.enabled = ([newTweet.text length] != 0);
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text 
{
	if([newTweet.text length] == 140 && range.length == 0) {
		return NO;
	}
	return YES;	
}

#pragma mark -
#pragma mark Picker View Delegate Methods

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [replyPeople count];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	if([replyPeople count] < row) return @"";
	NSDictionary *x = [replyPeople objectAtIndex:row];
	return [NSString stringWithFormat:@"%@ (%@)", [x valueForKey:@"name"], [x valueForKey:@"screen_name"]];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	if([replyPeople count] == 0) return;
	newTweet.text = [NSString stringWithFormat:@"%@%@ ", self.replyPrefix, [[replyPeople objectAtIndex:row] valueForKey:@"screen_name"]];
	[self textViewDidChange:newTweet];
}

#pragma mark -
#pragma mark UI Actions

-(IBAction)signOut:(id)sender 
{	
	if(!disableAnalytics) [[Beacon shared] startSubBeaconWithName:@"signout" timeSession:NO];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *cachePath = [self getFriendsCacheFileName];
	if([fm fileExistsAtPath:cachePath]) {
		[fm removeItemAtPath:cachePath error:nil];
	}
	self.replyPeople = [NSArray array];	
	[self oauthSignout];
	[newTweet resignFirstResponder];
	[self showSignin];
	
}

-(IBAction)postTweet:(id)sender
{
	//newTweet
	[newTweet resignFirstResponder];
	newTweet.editable = NO;
	
	//CGRect ptFrame = postingTweet.frame;
//	ptFrame.origin.x = 0;
//	ptFrame.origin.y = 244;
//	postingTweet.frame = ptFrame;
	[self.view addSubview:postingTweet];
	
	postTweetItem.enabled = NO;
	[NSThread detachNewThreadSelector:@selector(doPushTweet:) toTarget:self withObject:newTweet.text];
}

-(void)postTweetDone {
	if(!disableAnalytics) [[Beacon shared] startSubBeaconWithName:@"post tweet ok" timeSession:NO];
	[self postTweetDoneCommon];
	newTweet.text = @"";
	[self textViewDidChange:newTweet];
	NSRange r = NSMakeRange(0, [newTweet.text length]);
	[self textView:newTweet shouldChangeTextInRange:r replacementText:@""];
}

-(void)postTweetDoneCommon {
	[postingTweet retain];
	[postingTweet removeFromSuperview];
	postTweetItem.enabled = YES;
	newTweet.editable = YES;
	[newTweet becomeFirstResponder];
	
}

-(IBAction)about:(id)sender 
{
	[self showAboutScreen];
}

-(IBAction)signup:(id)sender 
{
	if(!disableAnalytics) [[Beacon shared] startSubBeaconWithName:@"signup" timeSession:NO];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://m.ac.nz/justupdate/iphone/signup"]];	
}

-(IBAction)reply:(id)sender 
{	
	if(!disableAnalytics) [[Beacon shared] startSubBeaconWithName:@"open reply" timeSession:NO];
	self.replyPrefix = @"@";
	replyPickerTitle.text = @"Send Reply To:";
	[replyPickerTitleBackground setImage:[UIImage imageNamed:@"PopupOverlay.png"] forState:UIControlStateNormal];
	[replyPickerTitleBackground setImage:[UIImage imageNamed:@"PopupOverlayHighlight.png"] forState:UIControlStateHighlighted];
	[self replyDMCommon];
}

-(IBAction)directMessage:(id)sender 
{
	if(!disableAnalytics) [[Beacon shared] startSubBeaconWithName:@"open dm" timeSession:NO];
	replyPickerTitle.text = @"Send Direct Message To:";
	self.replyPrefix = @"d ";
	[replyPickerTitleBackground setImage:[UIImage imageNamed:@"PopupOverlayDM.png"] forState:UIControlStateNormal];
	[replyPickerTitleBackground setImage:[UIImage imageNamed:@"PopupOverlayDMHighlight.png"] forState:UIControlStateHighlighted];
	[self replyDMCommon];
}

-(IBAction)hideReplyPicker:(id)sender
{
	[newTweet becomeFirstResponder];
	[replyPickerOverlay retain];
	[replyPickerOverlay removeFromSuperview];
	replyPickerOverlayVisible = NO;
}

-(IBAction)signinNow:(id)sender {

	// do sign in...
	[self initiateSignin];
	
}

#pragma mark -
#pragma mark Replies & DMs


-(void)replyDMCommon
{
	replyPickerOverlayVisible = YES;
	CGRect baseFrame =  [self orientateFrame:self.view.frame];
	baseFrame.origin.y = 0;	
	replyPickerOverlay.frame = baseFrame;
	[self.view addSubview:replyPickerOverlay];

	[newTweet resignFirstResponder];
	[replyPickerPerson becomeFirstResponder];
	
	[replyPickerPerson reloadAllComponents];
	
	if([replyPeople count] == 0) {		
		// first, try cache:
		NSString *r = [NSString stringWithContentsOfFile:[self getFriendsCacheFileName] encoding:NSUTF8StringEncoding error:nil];		
		if(r != nil) {
			[self peopleFromJSONString:r];
		}		
		
		[NSThread detachNewThreadSelector:@selector(updateFriends) toTarget:self withObject:nil];
	} else {
		// then we've been here before! hrm... let's find out who it was.
		NSInteger per = [replyPickerPerson selectedRowInComponent:0];
		[self pickerView:replyPickerPerson didSelectRow:per inComponent:0];
	}
}

#pragma mark -
#pragma mark Alert View Delegate Methods

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if([alertView.title isEqualToString:@"Anonymous Statistics"]) {
		if(buttonIndex == 0) {
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"JUDisableAnalytics"];
			disableAnalytics = YES;
			[[Beacon shared] endBeacon];
		}
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"JUConfirmedAnalytics"];
	}
}

-(void)verifySigninDone:(AuthdThreadArgs*)args
{
	
	NSMethodSignature *sig = [args.target methodSignatureForSelector:args.selector];
    if (sig) {		
		NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:sig];
		[invoke setSelector:args.selector]; 
		[invoke setArgument:(void *)&args atIndex:2]; // You want to pass the content of the element, which you don't know yet.
		[invoke invokeWithTarget:args.target];
    }
	[args autorelease];
}

#pragma mark -
#pragma mark API Methods (Threaded)

-(void)showTwitterUpdateFailedWithMessage:(NSString*)message {
	UIAlertView *uav = [[UIAlertView alloc] initWithTitle:@"Twitter Update Failed" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[uav show];
	[uav autorelease];
}

-(void)doPushTweet:(NSString*)t {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	NSLog(@"starting...");
	
	NSURL *url = [NSURL URLWithString:@"https://twitter.com/statuses/update.json"];
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url 
																   consumer:self.consumer 
																	  token:self.accessToken 
																	  realm:nil 
														  signatureProvider:nil];
	
	OARequestParameter *status = [[OARequestParameter alloc] initWithName:@"status" value:t];
	OARequestParameter *source = [[OARequestParameter alloc] initWithName:@"source" value:@"justupdate"];
	
	NSArray *params = [NSArray arrayWithObjects:status, source, nil];
	[status release];
	[source release];
	
	[request setHTTPMethod:@"POST"];
	[request setParameters:params];
	
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	[fetcher fetchDataWithRequest:request 
						 delegate:self 
				didFinishSelector:@selector(postTweetApiTicket:didFinishWithData:)
				  didFailSelector:@selector(postTweetApiTicket:didFailWithError:)];
	[request release];
	[fetcher release];
	
	NSLog(@"Finishing.");
	[[UIApplication sharedApplication] performSelectorOnMainThread:@selector(setNetworkActivityIndicatorVisible:) withObject:NO waitUntilDone:NO];
    [pool release];
}

-(void)postTweetApiTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)d {
	NSURLResponse *response = ticket.response;
	
	BOOL alreadyAlerted = NO;
	NSError *err = nil;
	
	NSString *m = nil;
	if(d != nil) { 
		NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)[response textEncodingName]));
		m = [[[NSString alloc] initWithBytes:[d bytes] length:[d length] encoding:encoding] autorelease];
		if(m == nil) {
			NSLog(@"m is still nil... d bytes, d, response: %s || %d || %@", [d bytes], [d length], response);
		}
	} else {
		NSLog(@"The specific error was: %@", err);
		[self performSelectorOnMainThread:@selector(showTwitterUpdateFailedWithMessage:) withObject:@"Couldn't connect to twitter, sorry." waitUntilDone:YES];
		alreadyAlerted = YES;
		if(!disableAnalytics) 
			[[Beacon shared] startSubBeaconWithName:@"connectFailed-1" timeSession:NO];
	}
	
	NSDictionary *dict = nil;
	if(m != nil) {
		dict = [m JSONValue];
	}
	
	if(dict != nil) {
		[self performSelectorOnMainThread:@selector(postTweetDone) withObject:nil waitUntilDone:NO];
	} else {
		if(!alreadyAlerted) {
			if(m != nil) {
				NSLog(@"m is not nil... d bytes, d, m, d length, response length: %s \n\n %@ \n\n %d \n\n %@", [d bytes], m, [d length], [NSNumber numberWithLongLong:[response expectedContentLength]]);
			}
			[self performSelectorOnMainThread:@selector(showTwitterUpdateFailedWithMessage:) withObject:@"We might be unable to reach twitter, or you may have changed your password." waitUntilDone:YES];
			if(!disableAnalytics)
				[[Beacon shared] startSubBeaconWithName:@"postTweetFailed-2" timeSession:NO];
		}
		[self performSelectorOnMainThread:@selector(postTweetDoneCommon) withObject:nil waitUntilDone:YES];
	}
	
}

- (void)postTweetApiTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
	[[[[UIAlertView alloc] initWithTitle:@"Update Twitter Failed" 
								 message:[error description] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease] show];
	NSLog(@"apiTicket failed with %@", error);
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

-(void)showTwitterCallFailedWithMessage:(NSString*)message {
	UIAlertView *uav = [[UIAlertView alloc] initWithTitle:@"Twitter Update Failed" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[uav show];
	[uav autorelease];
}

-(void)updateFriends {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	NSLog(@"starting...");
	
	
	NSString* path = [NSString stringWithFormat:@"https://twitter.com/statuses/friends/%@.json",  
					  [[[NSUserDefaults standardUserDefaults] valueForKey:@"JUUsername"] urlencode]];
	NSURL *url = [NSURL URLWithString:path];

	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url 
																   consumer:self.consumer 
																	  token:self.accessToken 
																	  realm:nil 
														  signatureProvider:nil];
	
	OARequestParameter *status = [[OARequestParameter alloc] initWithName:@"lite" value:@"true"];
	
	NSArray *params = [NSArray arrayWithObjects:status, nil];
	[status release];
	
	[request setHTTPMethod:@"GET"];
	[request setParameters:params];
	
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	[fetcher fetchDataWithRequest:request 
						 delegate:self 
				didFinishSelector:@selector(updateFriendsApiTicket:didFinishWithData:)
				  didFailSelector:@selector(updateFriendsApiTicket:didFailWithError:)];
	[request release];
	[fetcher release];
	
	NSLog(@"Finishing.");
	[[UIApplication sharedApplication] performSelectorOnMainThread:@selector(setNetworkActivityIndicatorVisible:) withObject:NO waitUntilDone:NO];
    [pool release];
}

-(void)updateFriendsApiTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)d {
	NSURLResponse *response = ticket.response;
	
	NSError *err = nil;
	
	NSString *m = nil;
	if(d != nil) { 
		NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)[response textEncodingName]));
		m = [[[NSString alloc] initWithBytes:[d bytes] length:[d length] encoding:encoding] autorelease];
		if(m == nil) {
			NSLog(@"m is still nil... d bytes, d, response: %s || %d || %@", [d bytes], [d length], response);
		}
	} else {
		NSLog(@"The specific error was: %@", err);
		[self performSelectorOnMainThread:@selector(showTwitterCallFailedWithMessage:) withObject:@"Couldn't connect to twitter, sorry." waitUntilDone:YES];
		if(!disableAnalytics) 
			[[Beacon shared] startSubBeaconWithName:@"connectFailed-1" timeSession:NO];
		return;
	}
	
	if (m == nil) {
		[self performSelectorOnMainThread:@selector(showTwitterCallFailedWithMessage:) withObject:@"It seems we can't talk to the server right now." waitUntilDone:YES];
		NSLog(@"Specific error for updateFriends was: %@", err);
		[newTweet performSelectorOnMainThread:@selector(becomeFirstResponder) withObject:nil waitUntilDone:YES];
		[replyPickerOverlay performSelectorOnMainThread:@selector(retain) withObject:nil waitUntilDone:YES];
		[replyPickerOverlay performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:YES];
	} else {
		[m writeToFile:[self getFriendsCacheFileName] atomically:YES encoding:NSUTF8StringEncoding error:nil];
		[self peopleFromJSONString:m];
	}
	
	
	
}

- (void)updateFriendsApiTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
	[[[[UIAlertView alloc] initWithTitle:@"Twitter Request Failed" 
								 message:[error description] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease] show];
	NSLog(@"apiTicket failed with %@", error);
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}


#pragma mark -
#pragma mark Auxillary Methods

-(void)peopleFromJSONString:(NSString*)jsonString
{
	NSArray *dict = [jsonString JSONValue];
	if(dict != nil) {
		self.replyPeople = dict;
		[self performSelectorOnMainThread:@selector(sortReplyPeople) withObject:nil waitUntilDone:YES];
		[replyPickerPerson performSelectorOnMainThread:@selector(reloadAllComponents) withObject:nil waitUntilDone:YES];
		// need to select the first person...
	}
}

-(void)sortReplyPeople
{        
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	self.replyPeople = [self.replyPeople sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}

-(NSString*)getFriendsCacheFileName
{
	NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:@"JUUsername"];	
	NSString *f = [NSString stringWithFormat:@"friends-%@.json", [username urlencode]];
	return [[self getDocumentsDirectory] stringByAppendingPathComponent:f];
}

// Creates a writable copy of the bundled default database in the application Documents directory.
-(NSString*)getDocumentsDirectory 
{
    // First, test for existence.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
	
#pragma mark Begin Workaround: create application "Documents" directory if needed
    // Workaround for Beta issue where Documents directory is not created during install.
    BOOL exists = [fileManager fileExistsAtPath:documentsDirectory];
    if (!exists) {
        BOOL success = [fileManager createDirectoryAtPath:documentsDirectory attributes:nil];
        if (!success) {
            NSAssert(0, @"Failed to create Documents directory.");
        }
    }
#pragma mark End Workaround
	
	return documentsDirectory;
}

#pragma mark -
#pragma mark About Screen Stuff


-(void)showAboutScreen
{
	[[Beacon shared] startSubBeaconWithName:@"openAbout" timeSession:NO];
	if(!disableAnalytics) [[Beacon shared] startSubBeaconWithName:@"open about" timeSession:NO];
	
	aboutScreenObjects = [[NSBundle mainBundle] loadNibNamed:@"AboutScreen" owner:self options:nil];
	[aboutScreenObjects retain];
	
	id iffyShort = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleShortVersionString"];
	id iffyBuild = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"];
	
	aboutVersion.text = [NSString stringWithFormat:@"Version %@ (%@)\n", iffyShort, iffyBuild];
	
	CGRect baseFrame = [self orientateFrame:self.view.frame];
	baseFrame.origin.y = baseFrame.origin.y + baseFrame.size.height;
	aboutView.frame = baseFrame;

	
	[self.view addSubview:aboutView];
	[UIView beginAnimations:@"showAboutView" context:nil];
	[newTweet resignFirstResponder];
	baseFrame =  [self orientateFrame:self.view.frame];
	baseFrame.origin.y = 0;
	
	aboutView.frame = baseFrame;
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationStopped:afterFinishing:withContext:)];
	[UIView commitAnimations];
}

-(void)dismissAboutScreenDone
{
	[aboutView retain];
	[aboutView removeFromSuperview];
	[aboutScreenObjects release];
	aboutScreenObjects = nil;
}

-(IBAction)aboutDismiss:(id)sender
{
	[UIView beginAnimations:@"hideAboutScreen" context:nil];
	
	CGRect baseFrame = [[UIScreen mainScreen] applicationFrame];
	baseFrame.origin.y = baseFrame.origin.y + baseFrame.size.height;
	aboutView.frame = baseFrame;
	
	[newTweet becomeFirstResponder];
	
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationStopped:afterFinishing:withContext:)];
	[UIView commitAnimations];	
}

-(IBAction)aboutVisitWebsite:(id)sender
{
	if(!disableAnalytics) [[Beacon shared] startSubBeaconWithName:@"open own website" timeSession:NO];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://m.ac.nz/justupdate/iphone/about"]];	
}

-(IBAction)aboutPrivacyPolicy:(id)sender
{
	if(!disableAnalytics) [[Beacon shared] startSubBeaconWithName:@"open privacy policy" timeSession:NO];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://m.ac.nz/justupdate/iphone/privacy"]];		
}

-(IBAction)aboutShowCredits:(id)sender {
	
	if([[aboutView subviews] containsObject:aboutCreditsView]) {
		
		
		[UIView beginAnimations:@"hideAboutCreditsView" context:nil];
		CGRect aboutViewFrame = aboutView.frame;
		CGFloat navHeight = 44;
		aboutViewFrame.origin.y = aboutViewFrame.size.height;
		aboutViewFrame.size.height = aboutViewFrame.size.height - navHeight;
		aboutCreditsView.frame = aboutViewFrame;
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationStopped:afterFinishing:withContext:)];
		[UIView commitAnimations];
		
		
		return;
	}
	
	
	[aboutView addSubview:aboutCreditsView];
	NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"html"]];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
	[aboutCreditsView loadRequest:urlRequest];
	
	CGRect aboutViewFrame = aboutView.frame;
	CGFloat navHeight = 44;
	aboutViewFrame.origin.y = aboutViewFrame.size.height;
	aboutViewFrame.size.height = aboutViewFrame.size.height - navHeight;
	aboutCreditsView.frame = aboutViewFrame;
	
	[UIView beginAnimations:@"showAboutCreditsView" context:nil];
	aboutViewFrame = aboutView.frame;
	aboutViewFrame.origin.y = navHeight;
	aboutViewFrame.size.height = aboutViewFrame.size.height - navHeight;
	aboutCreditsView.frame = aboutViewFrame;
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationStopped:afterFinishing:withContext:)];
	[UIView commitAnimations];
	
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSURL *url = [request URL];
	if([[url scheme] isEqualToString:@"file"]) {
		return YES;
	}
	[[UIApplication sharedApplication] openURL:url];	
	return NO;
}

#pragma mark -
#pragma mark OAuth

-(void)deferredSetup {
	OAToken *accessToken = self.accessToken;
	if(accessToken) {
	//	self.setup = YES;
	} else {
	//	self.setup = NO;
	}
	NSLog(@"Deferred setup... ?");
	[accessToken release];
	
}	

#pragma mark -
#pragma mark OAuth Consumer

-(OAConsumer*)consumer
{
	if(consumer == nil) {
		consumer = [[OAConsumer alloc] initWithKey:JUKey secret:JUSecret];
	}
	return consumer;
}

#pragma mark -
#pragma mark Request Token

-(BOOL)initiateSignin {
	
	OAToken *requestToken = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:@"auth_request"
																				   prefix:@"twitter"];
	
	if(requestToken) {
		[requestToken release];
		[self getAccessToken];
	} else {
		[self getRequestToken];
	}
	
	return requestToken != nil;
}

-(void)getRequestToken
{
	
    NSURL *url = [NSURL URLWithString:@"https://twitter.com/oauth/request_token"];
	
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
                                                                   consumer:[self consumer]
                                                                      token:nil   // we don't have a Token yet
                                                                      realm:nil   // our service provider doesn't specify a realm
                                                          signatureProvider:nil]; // use the default method, HMAC-SHA1
	
    [request setHTTPMethod:@"POST"];
	
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(requestTokenTicket:didFinishWithData:)
                  didFailSelector:@selector(requestTokenTicket:didFailWithError:)];	
	[request release];
}

- (void)requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
	if (ticket.didSucceed) {
		NSString *responseBody = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		OAToken *requestToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		[responseBody release];
		
		[requestToken storeInUserDefaultsWithServiceProviderName:@"auth_request" prefix:@"twitter"];
		
		NSString *urlString = [NSString stringWithFormat:@"https://twitter.com/oauth/authorize?oauth_token=%@&oauth_callback=%@",
							   requestToken.key, @"http://m.ac.nz/justupdate/auth-done"];
		NSLog(@"URL is: %@", urlString);
		NSURL *url = [NSURL URLWithString:urlString];
		
		
		if(!disableAnalytics) [[Beacon shared] startSubBeaconWithName:@"signinBegin" timeSession:NO];
		
		[[UIApplication sharedApplication] openURL:url];
		[requestToken release];
		
	}
}

- (void)requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
	[[[[UIAlertView alloc] initWithTitle:@"Request Ticket Failed" 
								 message:[error description] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease] show];
	
	NSLog(@"Failed with %@", error);
}

#pragma mark -
#pragma mark Acces Token

-(void)getAccessToken
{
	
	OAToken *requestToken = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:@"auth_request"
																				   prefix:@"twitter"];
	
	NSLog(@"Our key is: %@", requestToken.key);
	
	NSURL *url = [NSURL URLWithString:@"https://twitter.com/oauth/access_token"];
	
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																   consumer:self.consumer
																	  token:requestToken
																	  realm:nil   // our service provider doesn't specify a realm
														  signatureProvider:nil]; // use the default method, HMAC-SHA1
	
	[request setHTTPMethod:@"POST"];
	
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	
	[fetcher fetchDataWithRequest:request delegate:self
				didFinishSelector:@selector(accessTokenTicket:didFinishWithData:)
				  didFailSelector:@selector(accessTokenTicket:didFailWithError:)];	
	[request release];
	[requestToken release];
	
}

- (void)accessTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
	NSLog(@"requestTokenTicket2 didSucceed: %@", ticket.didSucceed ? @"Yes" : @"No");
	if (ticket.didSucceed) {
		NSString *responseBody = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		OAToken *requestToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		
		NSLog(@"Creating the token with... %@", responseBody);
		
		NSDictionary *resp = [self dictionaryFromQueryString:responseBody];
		
		[[NSUserDefaults standardUserDefaults] setObject:[resp objectForKey:@"screen_name"] forKey:@"JUUsername"];
		
		// we really need to capture the screen name...
		
		[responseBody release];
		
		[requestToken storeInUserDefaultsWithServiceProviderName:@"access"
														  prefix:@"twitter"];
		
		if(!disableAnalytics) [[Beacon shared] startSubBeaconWithName:@"signinComplete" timeSession:NO];
		// dismiss setup screen, for now, just...
		NSLog(@"Authenticated ok.");
		[requestToken release];
	}
}

- (void)accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
	
	if([error code] == -1012) {
		NSLog(@"try authenticating again...");
		[self getRequestToken];
		return;
	}
	
	[[[[UIAlertView alloc] initWithTitle:@"Access Ticket Failed" 
								 message:[error description] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease] show];
	
	NSLog(@"Failed with %@", error);
}


-(OAToken*)accessToken {
	OAToken *requestToken = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:@"access"
																				   prefix:@"twitter"];
	return [requestToken autorelease];
}

-(void)oauthSignout
{
	// remove the tokens
	NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
	
	NSString *prefix = @"twitter";
	NSString *provider = @"auth_request";
	[d removeObjectForKey:[NSString stringWithFormat:@"OAUTH_%@_%@_KEY", prefix, provider]];
	[d removeObjectForKey:[NSString stringWithFormat:@"OAUTH_%@_%@_SECRET", prefix, provider]];
	
	provider = @"access";
	[d removeObjectForKey:[NSString stringWithFormat:@"OAUTH_%@_%@_KEY", prefix, provider]];
	[d removeObjectForKey:[NSString stringWithFormat:@"OAUTH_%@_%@_SECRET", prefix, provider]];
	
	[d synchronize];
}	

@end
