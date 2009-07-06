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

#import <UIKit/UIKit.h>

@class AuthdThreadArgs;
@class OAToken;
@class OAConsumer;

@interface JustUpdateAppDelegate : UIViewController <UIApplicationDelegate, UITextViewDelegate, UIAlertViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIWebViewDelegate> {
	IBOutlet UIWindow *window;
	IBOutlet UIView *newTweetView;
	
	IBOutlet UINavigationItem *navigationItem;
	IBOutlet UINavigationBar *navigationBar;
	IBOutlet UIToolbar *postBar;
		
	IBOutlet UIBarButtonItem *charactersRemaining;
	IBOutlet UIBarButtonItem *postTweetItem;
	
	IBOutlet UITextView *newTweet;

	IBOutlet UIView *signinView;
	IBOutlet UINavigationItem *signInNavigationItem;
	IBOutlet UINavigationBar *signInNavigationBar;
	IBOutlet UIView *signinBoxes;
	
	IBOutlet UIView *replyPickerOverlay;
	IBOutlet UIPickerView *replyPickerPerson;
	IBOutlet UILabel *replyPickerTitle;
	IBOutlet UIButton *replyPickerTitleBackground;
	
	IBOutlet UIView *postingTweet;
	
	NSArray *replyPeople;
	NSString *replyPrefix;
	
	BOOL disableAnalytics;
	
	BOOL replyPickerOverlayVisible;
	
	
	NSArray *aboutScreenObjects;
	
	IBOutlet UIView *aboutView;
	IBOutlet UILabel *aboutVersion;
	
	IBOutlet UIView *scaler;
	
	OAConsumer *consumer;
	
	CGFloat currentStatusBarHeight;
	
	IBOutlet UIWebView *aboutCreditsView;
	IBOutlet UIBarButtonItem *aboutCredits;
}

@property (nonatomic, retain) UIWindow *window;
@property (retain) NSArray *replyPeople; 
@property (nonatomic, retain) NSString *replyPrefix;

@property (nonatomic, retain) UIView *scaler;

@property (readonly) OAConsumer *consumer;
@property (readonly) OAToken *accessToken;

-(void)showSignin;

-(IBAction)signOut:(id)sender;
-(IBAction)postTweet:(id)sender;
-(IBAction)about:(id)sender;
-(IBAction)signup:(id)sender;

-(IBAction)reply:(id)Sender;
-(IBAction)directMessage:(id)Sender;
-(IBAction)hideReplyPicker:(id)sender;

-(IBAction)signinNow:(id)sender;

-(void)postTweetDoneCommon;
-(void)replyDMCommon;

-(NSString*)getFriendsCacheFileName;

-(void)peopleFromJSONString:(NSString*)jsonString;
-(void)sortReplyPeople;
-(NSString*)getDocumentsDirectory;

-(void)showAboutScreen;
-(void)dismissAboutScreenDone;

-(IBAction)aboutDismiss:(id)sender;
-(IBAction)aboutVisitWebsite:(id)sender;
-(IBAction)aboutPrivacyPolicy:(id)sender;
-(IBAction)aboutShowCredits:(id)sender;

#pragma mark -
#pragma mark OAuth

-(BOOL)initiateSignin;
-(void)getRequestToken;
-(void)getAccessToken;
-(void)oauthSignout;

@end

