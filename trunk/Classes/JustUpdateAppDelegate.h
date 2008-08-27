//
//  JustUpdateAppDelegate.h
//  JustUpdate
//
//  Created by Patrick Quinn-Graham on 16/08/08.
//  Copyright Bunkerworld Publishing Ltd. 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JustUpdateViewController;
@class AuthdThreadArgs;

@interface JustUpdateAppDelegate : NSObject <UIApplicationDelegate, UITextViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
	IBOutlet UIWindow *window;
	IBOutlet UIView *newTweetView;
	
	IBOutlet UINavigationItem *navigationItem;
		
	IBOutlet UIBarButtonItem *charactersRemaining;
	IBOutlet UIBarButtonItem *postTweetItem;
	
	IBOutlet UITextView *newTweet;

	IBOutlet UIView *signinView;
	IBOutlet UITextField *signinUsername;
	IBOutlet UITextField *signinPassword;
	
	IBOutlet UIView *replyPickerOverlay;
	IBOutlet UIPickerView *replyPickerPerson;
	IBOutlet UILabel *replyPickerTitle;
	IBOutlet UIButton *replyPickerTitleBackground;
	
	IBOutlet UIView *postingTweet;
	
	NSArray *replyPeople;
	NSString *replyPrefix;
	
}

@property (nonatomic, retain) UIWindow *window;
@property (retain) NSArray *replyPeople; 
@property (nonatomic, retain) NSString *replyPrefix;

-(void)showSignin;

-(IBAction)signOut:(id)sender;
-(IBAction)postTweet:(id)sender;
-(IBAction)about:(id)sender;
-(IBAction)signup:(id)sender;

-(IBAction)reply:(id)Sender;
-(IBAction)directMessage:(id)Sender;
-(IBAction)hideReplyPicker:(id)sender;

-(void)postTweetDoneCommon;
-(void)replyDMCommon;

-(void)verifySignin:(NSString*)username andPassword:(NSString*)password withCallbackSelector:(SEL)sel target:(id)theTarget;
-(void)doVerifySignin:(AuthdThreadArgs*)credentials;


-(void)peopleFromJSONString:(NSString*)jsonString;
-(void)sortReplyPeople;
-(NSString*)getDocumentsDirectory;
	
@end

