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

//
//  JustUpdateAppDelegate.m
//  JustUpdate
//
//  Created by Patrick Quinn-Graham on 16/08/08.
//

#import "JustUpdateAppDelegate.h"
#import "AuthdThreadArgs.h"
#import "NSStringSyncAdditions.h"
#import "JSON.h"

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
	[defaults registerDefaults:dd];
	
	
	charactersRemaining.enabled = false;
	
	newTweetView.frame = [[UIScreen mainScreen] applicationFrame];
	
	[self.window addSubview:newTweetView];
	
	newTweet.text = @"";
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
}

-(void)showSignin 
{
	[self textViewDidChange:newTweet];
	
	signinView.frame = [[UIScreen mainScreen] applicationFrame];
	signinPassword.enabled = YES;
	signinUsername.enabled = YES;

	[self.window addSubview:signinView];
	[signinUsername becomeFirstResponder];
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
	if([replyPeople count] == 0) return @"";
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
	id iffy = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"];
	NSString *msg = [NSString stringWithFormat:@"Version %@\n© 2008 Patrick Quinn-Graham", iffy]; 
	UIAlertView *uav = [[UIAlertView alloc] initWithTitle:@"JustUpdate" message:msg delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Website", nil];
	[uav show];
	[uav autorelease];
}

-(IBAction)signup:(id)sender 
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://m.ac.nz/justupdate/iphone/signup"]];	
}

-(IBAction)reply:(id)sender 
{	
	self.replyPrefix = @"@";
	replyPickerTitle.text = @"Send Reply To:";
	[replyPickerTitleBackground setImage:[UIImage imageNamed:@"PopupOverlay.png"] forState:UIControlStateNormal];
	[replyPickerTitleBackground setImage:[UIImage imageNamed:@"PopupOverlayHighlight.png"] forState:UIControlStateHighlighted];
	[self replyDMCommon];
}

-(IBAction)directMessage:(id)sender 
{
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
	
	if([replyPeople count] == 0) {
		// first, try cache:
		NSString *r = [NSString stringWithContentsOfFile:[[self getDocumentsDirectory] stringByAppendingPathComponent:@"friends.json"] encoding:NSStringEncodingConversionExternalRepresentation error:nil];		
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
	if([alertView.title isEqualToString:@"JustUpdate"]) {
		if(buttonIndex == 1) {
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://m.ac.nz/justupdate/iphone"]];	
		}
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
		[signinView retain];
		[signinView removeFromSuperview];
		
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
			NSLog(@"M was: %@", m);
			UIAlertView *uav = [[UIAlertView alloc] initWithTitle:@"Twitter Update Failed" message:@"We might be unable to reach twitter, or you may have changed your password." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[uav show];
			[uav autorelease];
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
	
	NSString* path = [NSString stringWithFormat:@"https://%@:%@@twitter.com/statuses/friends.json",  
					  [[[NSUserDefaults standardUserDefaults] valueForKey:@"JUUsername"] urlencode], 
					  [[[NSUserDefaults standardUserDefaults] valueForKey:@"JUPassword"] urlencode]];
	
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
		[m writeToFile:[[self getDocumentsDirectory] stringByAppendingPathComponent:@"friends.json"] 
			atomically:YES encoding:NSStringEncodingConversionExternalRepresentation error:nil];
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

@end
