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

#import "JustUpdateAppDelegate.h"
#import "AuthdThreadArgs.h"
#import "NSStringSyncAdditions.h"
#import "JSON.h"
#import "Beacon.h"

@implementation JustUpdateAppDelegate

@synthesize window;
@synthesize replyPeople;
@synthesize replyPrefix;

-(void)applicationDidFinishLaunching:(UIApplication *)application 
{	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];		
	NSMutableDictionary *dd = [NSMutableDictionary dictionaryWithObject:@"" forKey:@"JUUsername"];
	[dd setValue:@"" forKey:@"JUPassword"];
	[dd setValue:@"NO" forKey:@"JUConfirmedAnalytics"];
	[dd setValue:@"NO" forKey:@"JUDisableAnalytics"];
	[defaults registerDefaults:dd];
	
		
	charactersRemaining.enabled = false;
	
	newTweetView.frame = [[UIScreen mainScreen] applicationFrame];
	
	[self.window addSubview:newTweetView];
	
	NSString *lastTweetText = [[NSUserDefaults standardUserDefaults] stringForKey:@"JUSavedTweet"];
	if(lastTweetText) {
		newTweet.text = lastTweetText;		
	} else {
		newTweet.text = @"";
	}
	
	newTweet.delegate = self;
	
	BOOL doSignin = YES;
	
	if(![[defaults valueForKey:@"JUUsername"] isEqualToString:@""] && 
	   ![[defaults valueForKey:@"JUPassword"] isEqualToString:@""]) {
		doSignin = NO;
	}
	
	if(doSignin) {
		[self showSignin];
	} else {
		navigationItem.title = [defaults valueForKey:@"JUUsername"];
		[newTweet becomeFirstResponder];
	}
	
	self.replyPeople = [NSArray array];
	
	[window makeKeyAndVisible];
	
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
}

-(NSDictionary*)dictionaryFromQueryString:(NSString*)query {
	
	NSArray *all = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *qsDict = [NSMutableDictionary dictionaryWithCapacity:[all count]];
	
	for(NSString *qsElement in all) {
		NSArray *qsElements = [qsElement componentsSeparatedByString:@"="];
		if([qsElements count] == 2) {
			NSString *key = [qsElements objectAtIndex:0];
			NSString *value = [[qsElements objectAtIndex:1] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
			NSString *valueValue = (NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)value, CFSTR(""), NSStringEncodingConversionExternalRepresentation);
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
	}
	
	return handledURL;
}

-(void)showSignin 
{
	[self textViewDidChange:newTweet];
	
	CGRect baseFrame = [[UIScreen mainScreen] applicationFrame];
	
	baseFrame.origin.y = baseFrame.origin.y + baseFrame.size.height;
	signinView.frame = baseFrame;
		
	signinPassword.enabled = YES;
	signinUsername.enabled = YES;

	[self.window addSubview:signinView];

	[UIView beginAnimations:@"showSignIn" context:nil];
	
	signinView.frame = [[UIScreen mainScreen] applicationFrame];
	[signinUsername becomeFirstResponder];
	
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
	[super dealloc];
}

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
	[[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"JUUsername"];
	[[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"JUPassword"];
	[self showSignin];
}

-(IBAction)postTweet:(id)sender
{
	//newTweet
	
	[newTweet resignFirstResponder];
	newTweet.editable = NO;
	
	CGRect fr = [[UIScreen mainScreen] applicationFrame];
	CGRect ptFrame = postingTweet.frame;
	ptFrame.origin.x = 0;
	ptFrame.origin.y = 22 + fr.size.height - ptFrame.size.height;	
	postingTweet.frame = ptFrame;
	[self.window addSubview:postingTweet];
	
	postTweetItem.enabled = NO;
	[NSThread detachNewThreadSelector:@selector(doPushTweet:) toTarget:self withObject:nil];
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
}

#pragma mark Replies & DMs


-(void)replyDMCommon
{
	replyPickerOverlay.frame = [[UIScreen mainScreen] applicationFrame];
	[self.window addSubview:replyPickerOverlay];
	[newTweet resignFirstResponder];
	[replyPickerPerson becomeFirstResponder];
	
	[replyPickerPerson reloadAllComponents];
	
	if([replyPeople count] == 0) {		
		// first, try cache:
		NSString *r = [NSString stringWithContentsOfFile:[self getFriendsCacheFileName] encoding:NSStringEncodingConversionExternalRepresentation error:nil];		
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

#pragma mark Text Fields (Sign-In) Delegate Methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField 
{

	if(textField == signinUsername) {
		[signinPassword becomeFirstResponder];
	}
	
	if(textField == signinPassword) {
		// do sign in!
		
		[signinPassword resignFirstResponder];
		signinPassword.enabled = NO;
		signinUsername.enabled = NO;
		[self verifySignin:signinUsername.text andPassword:signinPassword.text withCallbackSelector:@selector(siginDone:) target:self];
	}
	
	return NO;
}

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
	} else {		
		signinPassword.enabled = YES;
		signinUsername.enabled = YES;
		[signinUsername becomeFirstResponder];
	}
}

#pragma mark Sign-in Methods

-(void)siginDone:(AuthdThreadArgs*)args
{
	if(args.authOk) {
		if(!disableAnalytics)  [[Beacon shared] startSubBeaconWithName:@"signin" timeSession:NO];
		[self hideSignin];
		
		signinUsername.text = @"";
		signinPassword.text = @"";
		
		[[NSUserDefaults standardUserDefaults] setValue:args.username forKey:@"JUUsername"];
		[[NSUserDefaults standardUserDefaults] setValue:args.password forKey:@"JUPassword"];
		
		[newTweet becomeFirstResponder];
		navigationItem.title = args.username;
	} else {		
		UIAlertView *uav = [[UIAlertView alloc] initWithTitle:@"Twitter Authentication Failed" message:@"Check your details and try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[uav show];
		[uav autorelease];
	}
}

-(void)verifySignin:(NSString*)username andPassword:(NSString*)password withCallbackSelector:(SEL)sel target:(id)theTarget {
	AuthdThreadArgs *args = [[AuthdThreadArgs alloc] init];	
	args.username = username;
	args.password = password;
	args.selector = sel;
	args.target = theTarget;	
	[NSThread detachNewThreadSelector:@selector(doVerifySignin:) toTarget:self withObject:args];
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

#pragma mark API Methods (Threaded)

-(void)doVerifySignin:(AuthdThreadArgs*)credentials
{
	
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	NSString* path = [NSString stringWithFormat:@"https://%@:%@@twitter.com/account/verify_credentials.json", 
					  [credentials.username urlencode], [credentials.password urlencode]];
	
	NSString *m = [NSString stringWithContentsOfURL:[NSURL URLWithString:path]];
	
	if(![m isEqualToString:@"Could not authenticate you."]) {
		// everything is OK
		credentials.authOk = YES;
	} else {
		credentials.authOk = NO;
	}
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	[self performSelectorOnMainThread:@selector(verifySigninDone:) withObject:credentials waitUntilDone:NO];
	
    [pool release];
}

-(void)doPushTweet:(NSString*)t
{
	
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	

	NSString *tw = [NSString stringWithFormat:@"status=%@&source=justupdate", [newTweet.text urlencode]];
	
	NSString* path = [NSString stringWithFormat:@"https://%@:%@@twitter.com/statuses/update.json", 
					  [[[NSUserDefaults standardUserDefaults] valueForKey:@"JUUsername"] urlencode], 
					  [[[NSUserDefaults standardUserDefaults] valueForKey:@"JUPassword"] urlencode]];
	
	
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
	
	NSData *data = [tw dataUsingEncoding:NSStringEncodingConversionExternalRepresentation];
	
	[theRequest setHTTPMethod:@"POST"];
	[theRequest setHTTPBody:data];
	
	NSError *err;
	NSURLResponse *response;
	[theRequest setTimeoutInterval:30];
	NSData *d = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:&err];
	
	BOOL alreadyAlerted = NO;
	
	NSString *m = nil;
	if(d != nil) {
		m = [NSString stringWithCString:[d bytes]];
	} else {
		UIAlertView *uav = [[UIAlertView alloc] initWithTitle:@"Twitter Update Failed" message:@"Couldn't connect to twitter, sorry." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[uav show];
		[uav autorelease];
		alreadyAlerted = YES;
		if(!disableAnalytics) 
			[[Beacon shared] startSubBeaconWithName:@"connectFailed-1" timeSession:NO];
	}
	
	//NSLog(@"We asked for %@ with post %@ Got back %@", path, tw, m);
	
	NSDictionary *dict = nil;
	if(m != nil) {
		dict = [m JSONValue];
	}
	
	if(dict != nil) {
		[self performSelectorOnMainThread:@selector(postTweetDone) withObject:nil waitUntilDone:NO];
	} else {
		if(!alreadyAlerted) {
			//NSLog(@"M was: %@", m);
			UIAlertView *uav = [[UIAlertView alloc] initWithTitle:@"Twitter Update Failed" message:@"We might be unable to reach twitter, or you may have changed your password." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[uav show];
			[uav autorelease];
			if(!disableAnalytics)
				[[Beacon shared] startSubBeaconWithName:@"postTweetFailed-2" timeSession:NO];
		}
		[self performSelectorOnMainThread:@selector(postTweetDoneCommon) withObject:nil waitUntilDone:YES];
	}
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
    [pool release];
}

-(void)updateFriends
{
	
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	NSString* path = [NSString stringWithFormat:@"https://%@:%@@twitter.com/statuses/friends/%@.json?lite=true",  
					  [[[NSUserDefaults standardUserDefaults] valueForKey:@"JUUsername"] urlencode], 
					  [[[NSUserDefaults standardUserDefaults] valueForKey:@"JUPassword"] urlencode],  
					  [[[NSUserDefaults standardUserDefaults] valueForKey:@"JUUsername"] urlencode]];
		
	NSString *m = [NSString stringWithContentsOfURL:[NSURL URLWithString:path]];
	
	if (m == nil) {
		UIAlertView *uav = [[UIAlertView alloc] initWithTitle:@"Twitter Call Failed" message:@"It seems we can't talk to the server right now." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[uav show];
		[uav autorelease];
		[newTweet performSelectorOnMainThread:@selector(becomeFirstResponder) withObject:nil waitUntilDone:YES];
		[replyPickerOverlay performSelectorOnMainThread:@selector(retain) withObject:nil waitUntilDone:YES];
		[replyPickerOverlay performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:YES];
	} else if([m isEqualToString:@"Could not authenticate you."]) {
		UIAlertView *uav = [[UIAlertView alloc] initWithTitle:@"Twitter Call Failed" message:@"It looks like your password or username is wrong." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[uav show];
		[uav autorelease];
		[newTweet performSelectorOnMainThread:@selector(becomeFirstResponder) withObject:nil waitUntilDone:YES];
		[replyPickerOverlay performSelectorOnMainThread:@selector(retain) withObject:nil waitUntilDone:YES];
		[replyPickerOverlay performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:YES];
	} else {
		[m writeToFile:[self getFriendsCacheFileName] atomically:YES encoding:NSStringEncodingConversionExternalRepresentation error:nil];
		[self peopleFromJSONString:m];
	}
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	//[self performSelectorOnMainThread:@selector(replyPickerShown:) withObject:nil waitUntilDone:NO];
    [pool release];
}

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

#pragma mark About Screen Stuff

-(void)showAboutScreen
{
	[[Beacon shared] startSubBeaconWithName:@"openAbout" timeSession:NO];
	if(!disableAnalytics) [[Beacon shared] startSubBeaconWithName:@"open about" timeSession:NO];
	
	aboutScreenObjects = [[NSBundle mainBundle] loadNibNamed:@"AboutScreen" owner:self options:nil];
	[aboutScreenObjects retain];
	
	id iffy = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"];
	aboutVersion.text = [NSString stringWithFormat:@"Version %@\n", iffy];
	
	CGRect baseFrame = [[UIScreen mainScreen] applicationFrame];
	baseFrame.origin.y = baseFrame.origin.y + baseFrame.size.height;
	aboutView.frame = baseFrame;
	
	[self.window addSubview:aboutView];
	[UIView beginAnimations:@"showAboutView" context:nil];
	[newTweet resignFirstResponder];
	aboutView.frame = [[UIScreen mainScreen] applicationFrame];
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


@end
