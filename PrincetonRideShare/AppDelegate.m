//
//  AppDelegate.m
//  PrincetonRideShare
//
//  Created by Peter B Kramer on 6/6/15.
//  Copyright (c) 2015 Peter B Kramer. All rights reserved.
//

#import "AppDelegate.h"
#import "KeychainItemWrapper.h"
#import "SecondViewController.h"
#import "MessageViewController.h"

@interface AppDelegate (){
    
    NSMutableDictionary *parameters;
    BOOL registerNotificationsAsked;
    BOOL justEnteredForeground;
}


@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
   
    
    parameters=[[NSMutableDictionary alloc] init];
    [parameters setObject:[NSMutableArray arrayWithObjects:[[NSMutableDictionary alloc] init],[[NSMutableDictionary alloc] init],[[NSMutableDictionary alloc] init],[[NSMutableDictionary alloc] init],[[NSMutableDictionary alloc] init], nil] forKey:@"TheRides"];
    [parameters setObject:[NSNumber numberWithLong:0] forKey:@"RideSelected"];
    [parameters setObject:[NSNumber numberWithLong:0] forKey:@"iCloudRecordID"];
    [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"ReadAndAgreedTo"];
    NSError *errorDesc = nil;
    NSPropertyListFormat format;
    NSString *plistPath;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    plistPath = [rootPath stringByAppendingPathComponent:@"datafile"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
        NSMutableDictionary *tempReceipts =
        (NSMutableDictionary *)[NSPropertyListSerialization
                                propertyListWithData:plistXML
                                options:NSPropertyListMutableContainersAndLeaves
                                format:&format
                                error:&errorDesc];
        if(errorDesc){
         //   NSLog( @"error 2222   %@",errorDesc);
        }else{
            if ([tempReceipts objectForKey:@"Previous Notifications Archived"]){
                [tempReceipts setObject:[NSKeyedUnarchiver unarchiveObjectWithData:[tempReceipts objectForKey:@"Previous Notifications Archived"]] forKey:@"Previous Notifications"];
                [tempReceipts removeObjectForKey:@"Previous Notifications Archived"];
            }
            [parameters addEntriesFromDictionary:tempReceipts];
           // NSLog(@"recovered this:  %@",parameters);
        }
        
    }else{  //  no file, look for keychain
        KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"PrincetonRideShare" accessGroup:nil];
        
        
        
        //  USE THIS TO RESET THE Keychain for testing purposes
        //
        // [keychainItem resetKeychainItem];
        
    
        NSData *keychainValuedata=[keychainItem objectForKey:(__bridge id)kSecValueData];
        NSError *errorDesc1 = nil;
        NSPropertyListFormat format1;
        NSMutableDictionary *keychainDictionary =
            (NSMutableDictionary *)[NSPropertyListSerialization
                                propertyListWithData:keychainValuedata
                                options:NSPropertyListMutableContainersAndLeaves
                                format:&format1
                                error:&errorDesc1];
        if (keychainDictionary){
            [parameters addEntriesFromDictionary:keychainDictionary];
           // NSLog(@"the parameters from keychain are\n%@",parameters);
        }else{
          //  NSLog(@"no keychain - error    %@ ",errorDesc1);
        }
        
    }

    UITabBarController *tabController =(UITabBarController *)self.window.rootViewController;
    long numberOfNotifications=[[UIApplication sharedApplication] applicationIconBadgeNumber];
    if(numberOfNotifications>0){
        [[[tabController.viewControllers objectAtIndex:3] tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%li",numberOfNotifications] ];
    }
    
    [[tabController.viewControllers objectAtIndex:1] getParameters:parameters];
    [[tabController.viewControllers objectAtIndex:2] getParameters:parameters];
    [[tabController.viewControllers objectAtIndex:0] getParameters:parameters];
    [[tabController.viewControllers objectAtIndex:3] getParameters:parameters];
    
    
    justEnteredForeground=NO;
     
    return YES;
}


-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings{
    
  //  NSLog(@"the notifcations bit map is %lu      %@  ",(unsigned long)notificationSettings.types,notificationSettings);
    if(notificationSettings.types==0){
        UIAlertController* alert =
          [UIAlertController alertControllerWithTitle:@"Alerts disabled"
            message:@"Alerts will not appear on this device because you have disabled \"Notifications\" for this App.  To see Alerts launch the Settings App from the Home screen, select \"Notifications\" then select this App and then tap \"Allow Notifications\"."
            preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        [alert addAction:defaultAction];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

-(void)delayedDidReceiveNotification{
    
 //   NSLog(@"did receive notification called");
    UITabBarController *tabController =(UITabBarController *)self.window.rootViewController;
    
    if(!justEnteredForeground){  // set to trigger off 3 seconds after app re-enters foreground
      //  NSLog(@"incr3ementing here 1");
        //don't increment badge if this comes immediately after enter foreground
        int currentBadgeValue=[[[[tabController.viewControllers objectAtIndex:3] tabBarItem] badgeValue] intValue];
        [[[tabController.viewControllers objectAtIndex:3] tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%i",currentBadgeValue +1]];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:currentBadgeValue+1];
    }
    
    if([tabController selectedIndex]==3){
        [[tabController.viewControllers objectAtIndex:3] viewWillAppearStuff];
    }
    
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // add one to the badge of messages   if medssages is active then refresh the messages
    
    
    
 //   [self performSelector:@selector(delayedDidReceiveNotification) withObject:nil afterDelay:2.0f];
  //  CKNotification *cloudKitNotification = [CKNotification notificationFromRemoteNotificationDictionary:userInfo];
//    NSString *alertBody = cloudKitNotification.alertBody;
    
 //   NSLog(@"here is the value for........%@    %@    -%@-",[[userInfo objectForKey:@"aps"] objectForKey:@"sound"],[[userInfo objectForKey:@"aps"] objectForKey:@"alert"],alertBody);
    
    
    
    if([[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] count]>0){
  
    //    NSLog(@"did receive notification called");
        UITabBarController *tabController =(UITabBarController *)self.window.rootViewController;
        
        if(!justEnteredForeground){  // set to trigger off 3 seconds after app re-enters foreground
        //    NSLog(@"incr3ementing here 1");
            //don't increment badge if this comes immediately after enter foreground
            int currentBadgeValue=[[[[tabController.viewControllers objectAtIndex:3] tabBarItem] badgeValue] intValue];
            [[[tabController.viewControllers objectAtIndex:3] tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%i",currentBadgeValue +1]];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:currentBadgeValue+1];
        }
        
        if([tabController selectedIndex]==3){
            [[tabController.viewControllers objectAtIndex:3] viewWillAppearStuff];
        }
        
        
      //  NSLog(@"got a real notification   %@",userInfo);
    }else{
     //   NSLog(@"got a notification   %@",userInfo);  //   the ckmodifybadge sends a notification
        
    }
   
    
}




-(void)writeData{
 
    //  need to change this - "Previous Notifications"
    
    
   // NSLog(@"here 222222   %@",parameters);
    
    NSMutableDictionary *parametersDeepCopy=[NSKeyedUnarchiver unarchiveObjectWithData:
                                             [NSKeyedArchiver archivedDataWithRootObject:parameters]];
   // NSLog(@"here 234");
    NSArray *theRides=[parametersDeepCopy objectForKey:@"TheRides"];
    for(int I=0;I<[theRides count];I++){
        [[theRides objectAtIndex:I] removeObjectForKey:@"Nearby50"];
        [[theRides objectAtIndex:I] removeObjectForKey:@"TimeLastDownloaded"];
    }
    if([parametersDeepCopy objectForKey:@"Previous Notifications"]){
        [parametersDeepCopy setObject:[NSKeyedArchiver archivedDataWithRootObject:[parametersDeepCopy objectForKey:@"Previous Notifications"]] forKey:@"Previous Notifications Archived"];
        [parametersDeepCopy removeObjectForKey:@"Previous Notifications"];
    }
    NSError *error=nil;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"datafile"];
    
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:parametersDeepCopy format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    if(plistData){
        ([plistData writeToFile:plistPath atomically:YES]);
      //  NSLog(@"wrote the data file");
    }
    NSDictionary *keychainDictionary=[NSDictionary dictionaryWithObjectsAndKeys:[parameters objectForKey:@"ReadAndAgreedTo"],@"ReadAndAgreedTo",[parameters objectForKey:@"iCloudRecordID"],@"iCloudRecordID", nil];
    
   // NSLog(@"the parameters are %@",parameters);
    
    NSError *error1=nil;
    NSData *keychainValueData = [NSPropertyListSerialization dataWithPropertyList:keychainDictionary format:NSPropertyListXMLFormat_v1_0 options:0 error:&error1 ];
    if(keychainValueData){
        KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"PrincetonRideShare" accessGroup:nil];
        [keychainItem setObject: keychainValueData forKey:(__bridge id)kSecValueData];
     //   NSLog(@"wrote this to the keychain  %@",keychainDictionary);
    }
}




- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [self writeData];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

-(void)cancelJustEnteredForeground{
    justEnteredForeground=NO;
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    

    // if you tap the notification then it will call didReceiveRemoteNotification: and we don't want it to execute that routine at the launch so this variable stops it from executing for 1 second.
    justEnteredForeground=YES;
    [self performSelector:@selector(cancelJustEnteredForeground) withObject:nil afterDelay:1.0f];
    
    //FIXME:;
  //  NSLog(@"entering foreground");
    UITabBarController *tabController =(UITabBarController *)self.window.rootViewController;
    long numberOfNotifications=[[UIApplication sharedApplication] applicationIconBadgeNumber];
    if(numberOfNotifications>0){
        [[[tabController.viewControllers objectAtIndex:3] tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%li",numberOfNotifications] ];
    
       
       // [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    }
    if([tabController selectedIndex]==3){
        [[tabController.viewControllers objectAtIndex:3] viewWillAppearStuff];
    }
    
    
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
