//
//  Beacon+FBConnect.h
//  Pinch Media Analytics Library
//
//  Created by Kevin Cox on 3/17/09.
//  Copyright 2009 Pinch Media. All rights reserved.
//
//  Portions of this code are powered by Facebook Connect for iPhone
//    http://developers.facebook.com/connect.php?tab=iphone
//  Facebook Connect for iPhone Copyright 2009 Facebook
//
//  Facebook Connect for iPhone is licensed under the Apache License,
//  Version 2.0 (the "License"); you may not use this file except
//  in compliance with the License.
//  You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//
//  If you are using FBConnect in your project, this file
//  should be in your project alongside Beacon.h. Inside your
//  ViewController, or wherever you receive the session:didLogin:
//  message, import this file instead of Beacon.h. Then you
//  will be able to call the method below, and your app will
//  report user demographics.


#import "Beacon.h"
#import "FBConnect/FBSession.h"

@interface Beacon (Facebook)

// given a valid, logged-in FBSession, allow Beacon
// to collect user demographic data.
- (void)setFBConnectSession:(FBSession *)session;

@end
