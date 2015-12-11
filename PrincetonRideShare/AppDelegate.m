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
#import "CloudKitDatabase.h"
#import "CheckFor999.h"

@interface AppDelegate (){
    
    NSMutableDictionary *parameters;
    BOOL justEnteredForeground;
    BOOL iCloudIsAccessable;
    int randomNumber;
    NSMutableDictionary *theDataBaseStuff;
    CloudKitDatabase *theDataBase;
}


@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
   
    theDataBaseStuff=[[NSMutableDictionary alloc] initWithCapacity:10];
    int timeVariable=[NSDate timeIntervalSinceReferenceDate];
    randomNumber=abs((int)[[[[UIDevice currentDevice] identifierForVendor] UUIDString] hash])%10000000 +timeVariable%1000000;
    parameters=[[NSMutableDictionary alloc] init];
    [parameters setObject:[NSMutableArray arrayWithObjects:[[NSMutableDictionary alloc] init],[[NSMutableDictionary alloc] init],[[NSMutableDictionary alloc] init],[[NSMutableDictionary alloc] init],[[NSMutableDictionary alloc] init], nil] forKey:@"TheRides"];
    [parameters setObject:[NSNumber numberWithLong:0] forKey:@"RideSelected"];
    [parameters setObject:[NSNumber numberWithLong:0] forKey:@"iCloudRecordID"];
    [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"ReadAndAgreedTo"];
    [parameters setObject:[[NSMutableArray alloc] initWithObjects:@"No messages", nil] forKey:@"MyMessages"];
    [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"SubscriptionSwitch"];
    [parameters setObject:[NSNumber numberWithInt:0] forKey:@"MessageCounter"];
    [parameters setObject:[[NSMutableArray alloc] init] forKey:@"UpdateTheseRides"];
    [parameters setObject:[NSDate dateWithTimeIntervalSinceNow:-24*60*60] forKey:@"TimeOfLastUpdate"];
    [parameters setObject:[[NSMutableArray alloc] init] forKey:@"DontDisplayList"];
    
  //  [parameters setObject:[[NSArray alloc] init] forKey:@"Previous Notifications"];
  //  [parameters setObject:@"1.2" forKey:@"VersionNumber"];
    
    
    
    
    
   
    
    
    
    
    
    
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"PrincetonRideShare" accessGroup:nil];
    
    //  USE THIS TO RESET THE Keychain for testing purposes
    //      [keychainItem resetKeychainItem];
    
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
        if(![keychainDictionary objectForKey:@"VersionNumber"]){   //  it is version 1.1
            [parameters setObject:@"1.1" forKey:@"VersionNumber"];
        }
    }else{
        [self setCurrentVersionNumber];
    }
    
    
 //   [parameters setObject:@"1.1" forKey:@"VersionNumber"];
    
    
    NSString *dataPath;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    dataPath = [rootPath stringByAppendingPathComponent:@"datafile"];
    
    if([[parameters objectForKey:@"VersionNumber"] isEqualToString:@"1.1"]){
        NSError *errorDesc = nil;
        NSPropertyListFormat format;
        if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
            NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:dataPath];
            NSMutableDictionary *tempReceipts =
            (NSMutableDictionary *)[NSPropertyListSerialization
                                    propertyListWithData:plistXML
                                    options:NSPropertyListMutableContainersAndLeaves
                                    format:&format
                                    error:&errorDesc];
            if(!errorDesc){
                [parameters addEntriesFromDictionary:tempReceipts];
            }
        }
    }else{    //this is the current version, there may or may not be a file
        if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
            NSData *data = [[NSFileManager defaultManager] contentsAtPath:dataPath];
            NSMutableDictionary *tempReceipts =[NSKeyedUnarchiver unarchiveObjectWithData:data];
            [parameters addEntriesFromDictionary:tempReceipts];
        }
    }
    
    
    
    if([[parameters objectForKey:@"MyMessages"] count]==0)[[parameters objectForKey:@"MyMessages"] addObject:@"No messages"];
    if ([parameters objectForKey:@"Previous Notifications Archived"]){
        [parameters removeObjectForKey:@"Previous Notifications Archived"];
    }
    
    
    theDataBase=[[CloudKitDatabase alloc] initWithParameters:parameters];
    [theDataBase setUpTheDatabases];  // this will advance the version when it completes.
   
 //   CheckFor999 *checkWebsite=;
    [[[CheckFor999 alloc] init] getParameters:parameters ];
                               
    
    
    // This stuff will be done before the nested stuff above
    
    
     UITabBarController *tabController =(UITabBarController *)self.window.rootViewController;
    [[tabController.viewControllers objectAtIndex:1] getParameters:parameters];
    [[tabController.viewControllers objectAtIndex:2] getParameters:parameters];
    [[tabController.viewControllers objectAtIndex:0] getParameters:parameters];
    [[tabController.viewControllers objectAtIndex:3] getParameters:parameters]; // does stuff
    
    [self setTab3TabBarBadge];
    
    
    justEnteredForeground=NO;
    

    
    return YES;
}


-(void)setCurrentVersionNumber{
 //   NSLog(@"RESETTING");
    [parameters setObject:@"1.3" forKey:@"VersionNumber"];
}









/*

-(void)setUpTheDatabasesForVersion11{
    
    iCloudIsAccessable=NO;  // reset if icloud is correctly started
    
    [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        if (accountStatus == CKAccountStatusNoAccount) {
            [self iCloudErrorMessage:@"Unable to access iCloud.\nThis app uses iCloud for data storage and as a database.  Please activate your iCloud Account for this app otherwise you will not be able to store your Rides or send and receive Messages.  To activate your iCloud Account for this app, launch the Settings App, tap \"iCloud\", and enter your Apple ID.  Then turn \"iCloud Drive\" on and allow this App to store data.\nIf you don't have an iCloud account, tap \"Create a new Apple ID\"." ];
        }else if([[parameters objectForKey:@"iCloudRecordID"] intValue]==0){
                [self setCurrentVersionNumber];
                [self setUpTheDatabases];
        }else{
            CKContainer *defaultContainer=[CKContainer defaultContainer];
            CKDatabase *privateDatabase=[defaultContainer privateCloudDatabase];
            CKRecordID *myInfo = [[CKRecordID alloc] initWithRecordName:@"MyInfo"];
            [privateDatabase fetchRecordWithID:myInfo completionHandler:^(CKRecord *myInfoRecord, NSError *error) {
                NSDateFormatter *fullDateFormat=[[NSDateFormatter alloc] init];
                [fullDateFormat setDateFormat:@"MMM dd  h:mm:ss a"];
                
                if([error code]==CKErrorUnknownItem){  // no private database yet, create it
                    [self initializePrivateDataBase];
                    // there already is a public database so don't need to initialize it
                    //   get rides from public db.  NO  - theya re already here
                    
                }else if(error){ // a bad error
                    [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an iCloud error trying to access your database.  Please try again later.\n\n (%@)",error]];
                }else{  // already have myInfoRecord in private database
                    
                    [theDataBaseStuff setObject:[myInfoRecord objectForKey:@"iCloudRecordID"] forKey:@"iCloudRecordID"];
                    [theDataBaseStuff setObject:[myInfoRecord objectForKey:@"SubscriptionSwitch"] forKey:@"SubscriptionSwitch"];
                    [theDataBaseStuff setObject:[myInfoRecord objectForKey:@"MessageCounter"] forKey:@"MessageCounter"];
                    [theDataBaseStuff setObject:[myInfoRecord objectForKey:@"UnreadList"] forKey:@"UnreadList"];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *loseMessages=@" lose all of the Messages that are stored on this device and";
                        if([[[parameters objectForKey:@"MyMessages"] objectAtIndex:0] isKindOfClass:[NSString class]])
                            //@"No messages"
                            loseMessages=@"";
                        NSString *loseRides=@"";
                        for(int I=0;I<=4;I++){
                            if([[[parameters objectForKey:@"TheRides"] objectAtIndex:I] objectForKey:@"GeoA"]) loseRides=@" lose all of the Rides that are stored on this device.";
                        }
                        if(loseRides.length+loseMessages.length>2){
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Caution - Already Initialized"
                                message:[NSString stringWithFormat:@"You have already initialized your iCloud database from a different device logged into this iCloud Account.  If you proceed with this device under this same iCloud Account then you will %@%@",loseMessages,loseRides]
                                preferredStyle:UIAlertControllerStyleAlert];
                            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
                                [[parameters objectForKey:@"MyMessages"] removeAllObjects];
                                [[parameters objectForKey:@"MyMessages"] addObject:@"No messages"];
                                [parameters setObject:[NSNumber numberWithInt:0] forKey:@"MessageConter"];
                                [self downloadFromDb];
                            }]];
                            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                                [self iCloudErrorMessage:[NSString stringWithFormat: @"You chose to cancel activation of iCloud under this iCloud Account.  Please activate iCloud under this or another iCloud Account for this app otherwise you will not be able to store your Rides or send and receive Messages." ]];
                                
                            }]];
                            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                        }else{
                            [self downloadFromDb];  // there are no messages stored locally.  this is v1.1 so messagecounter will be 0
                        }
                        
                    });
                }
            }];
        }
       
    }];
    
    
}


-(void)setUpTheDatabases{
    
    
    iCloudIsAccessable=NO;  // reset if icloud is correctly started
    
    [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        if (accountStatus == CKAccountStatusNoAccount) {
            [self iCloudErrorMessage:@"Unable to access iCloud.\nThis app uses iCloud for data storage and as a database.  Please activate your iCloud Account for this app otherwise you will not be able to store your Rides or send and receive Messages.  To activate your iCloud Account for this app, launch the Settings App, tap \"iCloud\", and enter your Apple ID.  Then turn \"iCloud Drive\" on and allow this App to store data.\nIf you don't have an iCloud account, tap \"Create a new Apple ID\"." ];
            
        }else{  // version 1.2
            CKContainer *defaultContainer=[CKContainer defaultContainer];
            CKDatabase *privateDatabase=[defaultContainer privateCloudDatabase];
            CKRecordID *myInfo = [[CKRecordID alloc] initWithRecordName:@"MyInfo"];
            [privateDatabase fetchRecordWithID:myInfo completionHandler:^(CKRecord *myInfoRecord, NSError *error) {
                NSDateFormatter *fullDateFormat=[[NSDateFormatter alloc] init];
                [fullDateFormat setDateFormat:@"MMM dd  h:mm:ss a"];
                if([error code]==CKErrorUnknownItem){  // no private database yet, create it
                    if([[parameters objectForKey:@"iCloudRecordID"] intValue]==0){
                        [self getNewIDAndInitializeDb];
                    }else{
                        [self switchiCloudAccountsAlert:@"create a new"];
                    }
                }else if(error) {
                    //bad error
                    [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an iCloud error trying to access your database.  Please try again later.\n\n (%@)",error]];
                }else{
                    [theDataBaseStuff setObject:[myInfoRecord objectForKey:@"iCloudRecordID"] forKey:@"iCloudRecordID"];
                    [theDataBaseStuff setObject:[myInfoRecord objectForKey:@"SubscriptionSwitch"] forKey:@"SubscriptionSwitch"];
                    [theDataBaseStuff setObject:[myInfoRecord objectForKey:@"MessageCounter"] forKey:@"MessageCounter"];
                    [theDataBaseStuff setObject:[myInfoRecord objectForKey:@"UnreadList"] forKey:@"UnreadList"];
                    
                    
                    if([[parameters objectForKey:@"iCloudRecordID"] isEqualToNumber:[myInfoRecord objectForKey:@"iCloudRecordID"]]){
                        [self downloadFromDb];  //will have a value for messagecounter
                    }else{  //   local id# is not equal to id # in private db
                        [self switchiCloudAccountsAlert:@"switch to the"];
                    }
                    
                    
                    
                    
                    // ok here is the possibility - my icloudrecordid has never been set but a different device set it to something -
                    //   no error message, just download the data?
                    //      I assume if my recvordID is zero the token is nil so I will fetch all the data.
                    //      I want to zero any flags.  zero any rides?  zero any messages.  Then download the rides remark
                    
                    
                    
                    
                    
                    
                    
                }
                //check to see if number is the same
                // if it is
                
                
            }];
        }
        
    }];
    
    
    
    
    
}





-(void)switchiCloudAccountsAlert:(NSString *)condition{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *andRides=@"";
        if([condition isEqualToString:@"switch to the"])andRides=@" and Rides";
        UIAlertController *alert = [UIAlertController  alertControllerWithTitle:@"Change iCloud Account?"
            message:[NSString stringWithFormat:@"You seem to have changed iCloud Accounts.  Do you want to %@ database under this new iCloud Account and access it?  If you do, the Messages%@ currently stored on this device will not be transferred.",condition,andRides]
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            [[parameters objectForKey:@"MyMessages"] removeAllObjects];
            [[parameters objectForKey:@"MyMessages"] addObject:@"No messages"];
            [parameters setObject:[NSNumber numberWithInt:0] forKey:@"MessageConter"];
            if([condition isEqualToString:@"switch to the"]){
                [self downloadFromDb];
            }else{
                [parameters setObject:[NSNumber numberWithLong:0] forKey:@"iCloudRecordID"];
                [self getNewIDAndInitializeDb];
            }
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"No, cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
            [self iCloudErrorMessage:[NSString stringWithFormat: @"You chose to cancel accessing iCloud under your current iCloud Account.  Please activate iCloud under this or another iCloud Account for this app otherwise you will not be able to store your Rides or send and receive Messages." ]];
            
        }]];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

-(void)iCloudErrorMessage:(NSString *)message{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.window.rootViewController.presentedViewController){
            [self performSelector:@selector(iCloudErrorMessage:) withObject:message afterDelay:0.4f];
        }else{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"iCloud Error" message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Sorry" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

-(void)getNewIDAndInitializeDb{
    
    //   iCloudIsAccessable=YES;
    //  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    //     a
    
    
    CKContainer *defaultContainer=[CKContainer defaultContainer];
    CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
    
    srandom(randomNumber);
    randomNumber= abs( (int)random());
    randomNumber=randomNumber%10000000;
    if(randomNumber<1000001)randomNumber=randomNumber+1000001;
    //  between 1,000,001 and 9,999,999
    NSString *trialRecordIDName=[NSString stringWithFormat:@"%i0",randomNumber];
    CKRecordID *trialRecordID=[[CKRecordID alloc] initWithRecordName:trialRecordIDName];
    [publicDatabase fetchRecordWithID:trialRecordID completionHandler:^(CKRecord *fetchedRecord, NSError *error){
        if([error code]==CKErrorUnknownItem){  //  no such record exists, create it
            // NOT AN ERROR
            [parameters setObject:[NSNumber numberWithInt:randomNumber] forKey:@"iCloudRecordID"];
            //            NSLog(@"got a valid recordID");
            // [self getInitialSubscription];
            
            [self initializePrivateDataBase];
            [self initializePublicDatabase];

        }else if (!error){
            //     NSLog(@"trying a new number");
            [self getNewIDAndInitializeDb];// try a new random number for the trialRecordID
        }else{
            // NSLog(@"error in icloud 3745947");
            [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an error (2) trying to initialize your database.  Please try again later by restarting this app. (%@)",error]];
        }
    }];
    
}


-(void)initializePublicDatabase{
    
    NSDateFormatter *fullDateFormat=[[NSDateFormatter alloc] init];
    [fullDateFormat setDateFormat:@"MMM dd  h:mm:ss a"];
    
    CKContainer *defaultContainer=[CKContainer defaultContainer];
    CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
    
    
    
    
    int recordID=[[parameters objectForKey:@"iCloudRecordID"] intValue];
    
    NSMutableArray *recordIDs=[[NSMutableArray alloc] initWithCapacity:5];
    for (int I=0;I<=5;I++){
        [recordIDs addObject:[[CKRecordID alloc] initWithRecordName:[NSString stringWithFormat:@"%i%i",recordID,I]]];
    }
    
    NSMutableArray *theRecordsToSave=[[NSMutableArray alloc] initWithCapacity:5];
    
    CKRecord *zerothRecord=[[CKRecord alloc] initWithRecordType:@"Rides" recordID:[recordIDs objectAtIndex:0]];

    [theRecordsToSave addObject:zerothRecord];
    for(int I=1;I<=5;I++){
        CKRecord *aRecord=[[CKRecord alloc] initWithRecordType:@"Rides" recordID:[recordIDs objectAtIndex:I]];
        NSDictionary *aRide=[[parameters objectForKey:@"TheRides"] objectAtIndex:I-1];
    //    if([aRide objectForKey:@"GeoA"]){
      //      if(!aRecord){
        //        aRecord=[[CKRecord alloc] initWithRecordType:@"Rides" recordID:[recordIDs objectAtIndex:I]];
                //        NSLog(@"here 11112");
          //  }
            [aRecord setObject:[aRide objectForKey:@"ArriveEnd"] forKey:@"ArriveEnd"];
            [aRecord setObject:[aRide objectForKey:@"ArriveStart"] forKey:@"ArriveStart"];
            [aRecord setObject:[aRide objectForKey:@"LeaveEnd"] forKey:@"LeaveEnd"];
            [aRecord setObject:[aRide objectForKey:@"LeaveStart"] forKey:@"LeaveStart"];
            [aRecord setObject:[aRide objectForKey:@"DaysOfTheWeek"] forKey:@"DaysOfTheWeek"];
            [aRecord setObject:[aRide objectForKey:@"MyCarOrYours"] forKey:@"MyCarOrYours"];
            [aRecord setObject:[aRide objectForKey:@"GeoA"] forKey:@"GeoA"];
            [aRecord setObject:[aRide objectForKey:@"GeoAlat"] forKey:@"GeoAlat"];
            [aRecord setObject:[aRide objectForKey:@"GeoB"] forKey:@"GeoB"];
            [aRecord setObject:[aRide objectForKey:@"GeoBlat"] forKey:@"GeoBlat"];
            [aRecord setObject:[NSNumber numberWithInt:[[[recordIDs objectAtIndex:I] recordName] intValue]] forKey:@"IDNumber"];
            [aRecord setObject:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"TheDateLastAccessed"];  // an nsdate object
            [aRecord setObject:[fullDateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]] forKey:@"Title"];
            CLLocation *home=[[CLLocation alloc] initWithLatitude:[[aRide objectForKey:@"GeoAlat"] doubleValue] longitude:[[aRide objectForKey:@"GeoA"] doubleValue]];
            [aRecord setObject:home forKey:@"HomeLocation"];  // a CLLocation object
            
            
            [theRecordsToSave addObject:aRecord];
            //     NSLog(@"want to save these records:  %@",aRecord);
    //    }
    }
    if([theRecordsToSave count]>0){
        CKModifyRecordsOperation *modifyRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:theRecordsToSave recordIDsToDelete:nil];
        modifyRecords.modifyRecordsCompletionBlock=^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
            
            if(operationError){
                if(operationError.code==CKErrorPartialFailure){
                    NSLog(@"a partial error?????    %@",operationError);
                    //operationError=nil;
                }
            }
            if(operationError){
                
                int seconds=0;
                if(operationError.code==CKErrorServiceUnavailable || operationError.code==CKErrorRequestRateLimited)
                    seconds=[[[operationError userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                if(seconds>0){
                    [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to initialize your Rides database.  Please try again after %i seconds.",seconds]];
                }else{
                    [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an error trying to initialize your Rides database.  Please try again later. (%@)",operationError]];
                }
            }else{
                //    NSLog(@"saved these records:  %@",savedRecords);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    [parameters setObject:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"TimeOfLastUpdate"];
                });
            }
        };
        //   NSLog(@"and here is the complete set just befiore add operation  %@",theRecordsToSave);
        [publicDatabase addOperation:modifyRecords];
    }

}


//need to set messagecounter

//  set it to 0, add it to each message locally and to the record, ++ it
//

// there may be messages left over from version 1.1.
//   we will recreate the ckrecord and save it to the provate database.  But we will add a messagecounter so we can query it for messageconter> then what is on board at that time.
// each message should have a message counter value here that can be found by searching for >0
// let's count them one at a time for good historical record keeping.


-(void)initializePrivateDataBase{
    // there may or may not be messages to upload.
    // any messages that are uploaded will be downloaded when getMessages is run because not resetting messageCounter after this upload - it remains 0
    CKContainer *defaultContainer=[CKContainer defaultContainer];
    CKDatabase *privateDatabase=[defaultContainer privateCloudDatabase];
    CKRecordID *myInfo = [[CKRecordID alloc] initWithRecordName:@"MyInfo"];
    NSMutableArray *messageArray=[parameters objectForKey:@"MyMessages"];
    NSDateFormatter *fullDateFormat=[[NSDateFormatter alloc] init];
    [fullDateFormat setDateFormat:@"MMM dd  h:mm:ss a"];
    NSMutableArray *theRecordsToSave=[[NSMutableArray alloc] initWithCapacity:[messageArray count]+1];
    NSMutableArray *theUnreadList=[[NSMutableArray alloc] initWithCapacity:[messageArray count]];
    int messageCounter=[[parameters objectForKey:@"MessageCounter"] intValue];
    if(![[messageArray objectAtIndex:0] isKindOfClass:[NSString class]]){
        for(int I=0;I<[messageArray count];I++){
            messageCounter++;  // first message will show up if you search for >0
            NSMutableDictionary *aMessageToUpload=[[NSMutableDictionary alloc] initWithDictionary:[messageArray objectAtIndex:I]];
            [aMessageToUpload setObject:[NSNumber numberWithInt:messageCounter] forKey:@"MessageCenter"];
            [messageArray replaceObjectAtIndex:I withObject:[NSDictionary dictionaryWithDictionary:aMessageToUpload]];
            if([[aMessageToUpload objectForKey:@"Read"] isEqualToString:@"Just downloaded"])[theUnreadList addObject:[NSNumber numberWithInt:messageCounter]];
            CKRecordID *aCKRecordId=[[CKRecordID alloc] initWithRecordName: //@"a name here" ];
                                     [NSString stringWithFormat:@"%@ to %@ on %@",
                                      [aMessageToUpload objectForKey:@"From"],
                                      [aMessageToUpload objectForKey:@"ToNumber"],
                                      [fullDateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:[[aMessageToUpload objectForKey:@"DateD"] doubleValue]]]]];
            CKRecord *aMessage=[[CKRecord alloc] initWithRecordType:@"Messages" recordID:aCKRecordId];
            [aMessage setObject:[aMessageToUpload objectForKey:@"ToNumber"]  forKey:@"ToNumber"];
            [aMessage setObject:[aMessageToUpload objectForKey:@"ToRide"]  forKey:@"ToRide"];
            [aMessage setObject:[aMessageToUpload objectForKey:@"FromRide"]  forKey:@"FromRide"];
            [aMessage setObject:[aMessageToUpload objectForKey:@"From"]  forKey:@"From"];
            [aMessage setObject:[aMessageToUpload objectForKey:@"Message"]  forKey:@"Message"];
            [aMessage setObject:[aMessageToUpload objectForKey:@"DateD"]  forKey:@"DateD"];
            [aMessage setObject:[aMessageToUpload objectForKey:@"Title"]  forKey:@"Title"];
            [aMessage setObject:[aMessageToUpload objectForKey:@"MessageCounter"] forKey:@"MessageCounter"];
            [theRecordsToSave addObject:aMessage];
            
            NSLog(@"here is a record:  %@   %f    %@",aMessage,[[aMessageToUpload objectForKey:@"DateD"] doubleValue],[fullDateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:[[aMessageToUpload objectForKey:@"DateD"] doubleValue]]]);
            
            
            
            
        }
    }

    
    CKRecord *myInfoRecord=[[CKRecord alloc] initWithRecordType:@"Info" recordID:myInfo];
    [myInfoRecord setObject:[parameters objectForKey:@"iCloudRecordID"] forKey:@"iCloudRecordID"];
    [myInfoRecord setObject:[parameters objectForKey:@"SubscriptionSwitch"] forKey:@"SubscriptionSwitch"];
    [myInfoRecord setObject:[NSNumber numberWithInt:messageCounter] forKey:@"MessageCounter"];
    [myInfoRecord setObject:theUnreadList forKey:@"UnreadList"];
    [theRecordsToSave addObject:myInfoRecord];
    NSLog(@"here is a record:  %@",myInfoRecord);
    
    NSArray *theRecordsToSaveArray=[NSArray arrayWithArray:theRecordsToSave];
    CKModifyRecordsOperation *modifyRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:theRecordsToSaveArray recordIDsToDelete:nil];
    modifyRecords.modifyRecordsCompletionBlock=^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
        if(operationError){
            if(operationError.code==CKErrorPartialFailure){
                NSLog(@"a partial error?????  WHAT DO I DO????  %@",operationError);
                //operationError=nil;
            }
        }
        if(operationError){
            int seconds=0;
            if(operationError.code==CKErrorServiceUnavailable || operationError.code==CKErrorRequestRateLimited)
                seconds=[[[operationError userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
            if(seconds>0){
                [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to create your database.  Please try again by restarting this app after %i seconds.\n\n(%@)",seconds,operationError]];
            }else{
                //     NSLog(@"the error was  %@",operationError);
                [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an iCloud error trying to create your database.  Please try again later by restarting this app.\n\n (%@)",operationError]];
            }
        }else{
            //    NSLog(@"saved these records:  %@",savedRecords);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[parameters objectForKey:@"MyMessages"] removeAllObjects]; //they will be downloaded when getMessages is run.
                iCloudIsAccessable=YES;
                [self setCurrentVersionNumber];//success (might be v1.1)
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            });
        }
    };
    [privateDatabase addOperation:modifyRecords];
}

-(void)downloadFromDb{   // note - not on main thread
    
    iCloudIsAccessable=YES;
    [self setCurrentVersionNumber];//success (might be v1.1)
  //  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    
    [parameters setObject:[theDataBaseStuff objectForKey:@"iCloudRecordID"] forKey:@"iCloudRecordID"];
    [parameters setObject:[theDataBaseStuff objectForKey:@"SubscriptionSwitch"] forKey:@"SubscriptionSwitch"];
    
    
    //?????  no longer need to do this.  It will be done in Tab 4 at getMessage.
    */
    /* previously---
    NSMutableArray *messagesToRetrieve=[[NSMutableArray alloc] init];
    if([[[parameters objectForKey:@"MyMessages"] objectAtIndex:0] isKindOfClass:[NSString class]]){
        for(int I=0;I<[[theDataBaseStuff objectForKey:@"MessageList"] count];I++){
            [messagesToRetrieve addObject:[[CKRecordID alloc] initWithRecordName:[[theDataBaseStuff objectForKey:@"MessageList"] objectAtIndex:I]]];
        }
    }else{
        
        NSArray *messageDatesD=[[parameters objectForKey:@"MyMessages"] valueForKey:@"DateD"];  // the datesd for each message
        NSLog(@"the message dates are %@",messageDatesD);
        for(int I=0;I<[[theDataBaseStuff objectForKey:@"MessageList"] count];I++){
            if(![messageDatesD containsObject:[[theDataBaseStuff objectForKey:@"MessageList"] objectAtIndex:I]]){
                [messagesToRetrieve addObject:[[CKRecordID alloc] initWithRecordName:[[theDataBaseStuff objectForKey:@"MessageList"] objectAtIndex:I]]];
                
                
                //record name must be a string... what should I use.  I will fetch records.  I will delete by record name though - and the record that I will be deleted can be named by the dated value?
                
                
            }
        }
    }
    NSMutableArray *myMessages=[parameters objectForKey:@"MyMessages"];
    for(long I=[myMessages count]-1;I>=0;I--){
        if(![[theDataBaseStuff objectForKey:@"MessageList"] containsObject:[[myMessages objectAtIndex:I] objectForKey:@"DatesD"]]){
            [myMessages removeObjectAtIndex:I];
        }else if(![[theDataBaseStuff objectForKey:@"UnreadList"] containsObject:[[myMessages objectAtIndex:I] objectForKey:@"DatesD"]]){
            [[myMessages objectAtIndex:I] setObject:@"Yes" forKey:@"Read"];
        }
    }
    
    
    
    CKFetchRecordsOperation *fetchRecords=[[CKFetchRecordsOperation alloc] initWithRecordIDs:messagesToRetrieve];
    fetchRecords.fetchRecordsCompletionBlock= ^(NSDictionary *recordsByRecordID,NSError *error){
        if(error){
            if(error.code==CKErrorPartialFailure)error=nil;
        }
        if(error){
            int seconds=0;
            if(error.code==CKErrorServiceUnavailable || error.code==CKErrorRequestRateLimited)
                seconds=[[[error userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
            if(seconds>0){
                [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue (1) trying to retrieve your Messages.  Please try again after %i seconds.",seconds]];
            }else{
                [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an error (1) trying to retrieve your Messages.  Please try again later. (%@)",error]];
            }
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                NSMutableArray *theResults=[[NSMutableArray alloc] initWithArray:[recordsByRecordID allValues]];
                
                for(int I=0;I<[theResults count];I++){
                    NSDictionary *aMessage=[theResults objectAtIndex:I];
                    NSString *readString=[aMessage objectForKey:@"Read"];
                    if(![[theDataBaseStuff objectForKey:@"UnreadList"] containsObject:[aMessage objectForKey:@"DatesD"]]){
                        readString=@"Yes";
                    }
                    NSDictionary *thisMessage=[[NSDictionary alloc] initWithObjectsAndKeys:[aMessage objectForKey:@"From"],@"From",[aMessage objectForKey:@"ToNumber"],@"ToNumber",[aMessage objectForKey:@"ToRide"],@"ToRide",[aMessage objectForKey:@"FromRide"],@"FromRide",[aMessage objectForKey:@"Message"],@"Message",[aMessage objectForKey:@"DateD"],@"DateD",readString,@"Read",nil];
                    [myMessages addObject:thisMessage];
                    if([[myMessages objectAtIndex:0] isEqual:@"No messages"])[myMessages removeObjectAtIndex:0];
                }
            });
        }
    };
    [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:fetchRecords];
    
    */
    
    /*
    
    
    
    
    
    
    
    
    
    
    
    int recordID=[[parameters objectForKey:@"iCloudRecordID"] intValue];
    NSMutableArray *recordIDs=[[NSMutableArray alloc] initWithCapacity:5];
    for (int I=1;I<=5;I++){
        [recordIDs addObject:[[CKRecordID alloc] initWithRecordName:[NSString stringWithFormat:@"%i%i",recordID,I]]];
    }
    CKFetchRecordsOperation *fetchRidesRecords=[[CKFetchRecordsOperation alloc] initWithRecordIDs:recordIDs];
    fetchRidesRecords.fetchRecordsCompletionBlock= ^(NSDictionary *recordsByRecordID,NSError *error){
        if(error){
            if(error.code==CKErrorPartialFailure)error=nil;  // not all rides are posted
        }
        if(error){
            int seconds=0;
            if(error.code==CKErrorServiceUnavailable || error.code==CKErrorRequestRateLimited)
                seconds=[[[error userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
            if(seconds>0){
                [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue (1) trying to read your Rides from iCloud.  Please try again after %i seconds.",seconds]];
            }else{
                //   NSLog(@"error is %ld   %@",(long)error.code,error);
                [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an error (1) trying to read your Rides from iCloud.  Please try again later. (%@)",error]];
            }
        }else{
            for(int I=1;I<=5;I++){
                CKRecord *aRide=[recordsByRecordID objectForKey:[recordIDs objectAtIndex:I-1]];
                NSMutableDictionary *aRecord=[[parameters objectForKey:@"TheRides"] objectAtIndex:I-1];
                
                [aRecord removeObjectForKey:@"ArriveEnd"];
                [aRecord removeObjectForKey: @"ArriveStart"];
                [aRecord removeObjectForKey: @"LeaveEnd"];
                [aRecord removeObjectForKey: @"LeaveStart"];
                [aRecord removeObjectForKey: @"DaysOfTheWeek"];
                [aRecord removeObjectForKey: @"MyCarOrYours"];
                [aRecord removeObjectForKey: @"GeoA"];
                [aRecord removeObjectForKey: @"GeoAlat"];
                [aRecord removeObjectForKey: @"GeoB"];
                [aRecord removeObjectForKey: @"GeoBlat"];
                [aRecord removeObjectForKey: @"TheDateLastAccessed"];
                [aRecord removeObjectForKey: @"Title"];
                
                
                if(aRide){  // there might not be one returned by the fetch command - in which case it gets nulled
                    if([aRide objectForKey:@"ArriveEnd"])  [aRecord setObject:[aRide objectForKey:@"ArriveEnd"] forKey:@"ArriveEnd"];
                    if([aRide objectForKey:@"ArriveStart"]) [aRecord setObject:[aRide objectForKey:@"ArriveStart"] forKey:@"ArriveStart"];
                    if([aRide objectForKey:@"LeaveEnd"])[aRecord setObject:[aRide objectForKey:@"LeaveEnd"] forKey:@"LeaveEnd"];
                    if([aRide objectForKey:@"LeaveStart"])[aRecord setObject:[aRide objectForKey:@"LeaveStart"] forKey:@"LeaveStart"];
                    if([aRide objectForKey:@"DaysOfTheWeek"])[aRecord setObject:[aRide objectForKey:@"DaysOfTheWeek"] forKey:@"DaysOfTheWeek"];
                    if([aRide objectForKey:@"MyCarOrYours"])[aRecord setObject:[aRide objectForKey:@"MyCarOrYours"] forKey:@"MyCarOrYours"];
                    if([aRide objectForKey:@"GeoA"])[aRecord setObject:[aRide objectForKey:@"GeoA"] forKey:@"GeoA"];
                    if([aRide objectForKey:@"GeoAlat"]) [aRecord setObject:[aRide objectForKey:@"GeoAlat"] forKey:@"GeoAlat"];
                    if([aRide objectForKey:@"GeoB"])[aRecord setObject:[aRide objectForKey:@"GeoB"] forKey:@"GeoB"];
                    if([aRide objectForKey:@""])[aRecord setObject:[aRide objectForKey:@"GeoBlat"] forKey:@"GeoBlat"];
                    if([aRide objectForKey:@"TheDateLastAccessed"])[aRecord setObject:[aRide objectForKey:@"TheDateLastAccessed"] forKey:@"TheDateLastAccessed"];
                    if([aRide objectForKey:@"Title"])[aRecord setObject:[aRide objectForKey:@"Title"] forKey:@"Title"];
                    NSLog(@"just set the following:   %@",aRecord);
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            });
    
        }
    };
    [[[CKContainer defaultContainer] publicCloudDatabase] addOperation:fetchRidesRecords];
}
*/









/*
-(void)setTabBadge:(UITabBarItem *)theTabBarItem{
 
 
    long numberOfMessages=[[UIApplication sharedApplication] applicationIconBadgeNumber];
 
    NSArray *myMessages=[parameters objectForKey:@"MyMessages"];
    for(int I=0;I<[myMessages count];I++){
        if([[myMessages objectAtIndex:I] isKindOfClass:[NSDictionary class]]){
            if([[[myMessages objectAtIndex:I] objectForKey:@"Read"] isEqualToString:@"Just downloaded"])
                numberOfMessages++;
        }
    }
    if(numberOfMessages>0){
        theTabBarItem.badgeValue=[NSString stringWithFormat:@"%li",numberOfMessages];
    }else{
        theTabBarItem.badgeValue=nil;
    }
    
    
}
*/

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
/*
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
*/

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // add one to the badge of messages   if medssages is active then refresh the messages
    
    
    
 //   [self performSelector:@selector(delayedDidReceiveNotification) withObject:nil afterDelay:2.0f];
  //  CKNotification *cloudKitNotification = [CKNotification notificationFromRemoteNotificationDictionary:userInfo];
//    NSString *alertBody = cloudKitNotification.alertBody;
    
 //   NSLog(@"here is the value for........%@    %@    -%@-",[[userInfo objectForKey:@"aps"] objectForKey:@"sound"],[[userInfo objectForKey:@"aps"] objectForKey:@"alert"],alertBody);
    
    
    
    if([[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] count]>0){
  
        // NSLog(@"did receive notification called");
        
        if(!justEnteredForeground){  // set to trigger off 3 seconds after app re-enters foreground
        //    NSLog(@"incr3ementing here 1");
            //don't increment badge if this comes immediately after enter foreground
            
            // test to see if notification is for you.
            //     if so, add one to the icon
            
            UITabBarController *tabController =(UITabBarController *)self.window.rootViewController;
       //     UIViewController *tab3VC=[tabController.viewControllers objectAtIndex:3];
       //     NSString *theBadge=[[tab3VC tabBarItem] badgeValue];
      //      int currentBadgeValue=0;
      //      if([theBadge rangeOfString:@"+"].length>0)
      //          currentBadgeValue=[[theBadge substringFromIndex:[theBadge rangeOfString:@"+"].location+1] intValue];
      //      [[tab3VC tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%i+%i",[theBadge intValue],currentBadgeValue+1]];
            long badgeNumber=[[UIApplication sharedApplication] applicationIconBadgeNumber]+1;
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badgeNumber];
            [self setTab3TabBarBadge];
            
            
            
    //        [parameters setObject:[NSNumber numberWithLong:badgeNumber] forKey:@"AppIconBadgeNumber"];
            if([tabController selectedIndex]==3){
                [[tabController.viewControllers objectAtIndex:3] callNewNotificationArrivedAfterDelay];
            }
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
  /*  if([parametersDeepCopy objectForKey:@"Previous Notifications"]){
   //     [parametersDeepCopy setObject:[NSKeyedArchiver archivedDataWithRootObject:[parametersDeepCopy objectForKey:@"Previous Notifications"]] forKey:@"Previous Notifications Archived"];
        [parametersDeepCopy removeObjectForKey:@"Previous Notifications"];
    }*/
    NSError *error=nil;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *dataPath = [rootPath stringByAppendingPathComponent:@"datafile"];
    
    
    if([[parameters objectForKey:@"VersionNumber"] isEqualToString:@"1.1"]){
        NSData *data = [NSPropertyListSerialization dataWithPropertyList:parametersDeepCopy format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
        if(data){
            [data writeToFile:dataPath atomically:YES];
            //  NSLog(@"wrote the data file");
        }
    }else{
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:parametersDeepCopy];
        [data writeToFile:dataPath atomically:YES];
    }

    
    NSDictionary *keychainDictionary=[NSDictionary dictionaryWithObjectsAndKeys:[parameters objectForKey:@"ReadAndAgreedTo"],@"ReadAndAgreedTo",[parameters objectForKey:@"iCloudRecordID"],@"iCloudRecordID",[parameters objectForKey:@"VersionNumber"],@"VersionNumber",[parameters objectForKey:@"MessageIssue"],@"MessageIssue",nil];
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

-(void)setTab3TabBarBadge{
    long badgeNumber=[[UIApplication sharedApplication] applicationIconBadgeNumber];
    UITabBarController *tabController =(UITabBarController *)self.window.rootViewController;
    if(badgeNumber>0){
        [[[tabController.viewControllers objectAtIndex:3] tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%li",badgeNumber]];
    }else{
        [[[tabController.viewControllers objectAtIndex:3] tabBarItem] setBadgeValue:nil];
    }
}





- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    
    // if you tap the notification then it will call didReceiveRemoteNotification: and we don't want it to execute that routine at the launch so this variable stops it from executing for 1 second.
    justEnteredForeground=YES;
    [self performSelector:@selector(cancelJustEnteredForeground) withObject:nil afterDelay:1.0f];
 
    
    //[self setUpTheDatabases];
 //   if([[parameters objectForKey:@"VersionNumber"] isEqualToString:@"1.1"]){   //  it is version 1.1
   //     [self setUpTheDatabasesForVersion11];
   // }else{
     //   [self setUpTheDatabases];
    //}
    
    [theDataBase setUpTheDatabases];  // this will advance the version when it completes.
    
    
    [[[CheckFor999 alloc] init] getParameters:parameters ];
    
    [self setTab3TabBarBadge];
    
    
    UITabBarController *tabController =(UITabBarController *)self.window.rootViewController;
    if([tabController selectedIndex]==3){
        [[tabController.viewControllers objectAtIndex:3] viewWillAppearStuff];
        // this will alert if there are extra notifications
        
        //might be doing messages before database is setup?????
        
        
        
        
        
    }
    
    
  
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
