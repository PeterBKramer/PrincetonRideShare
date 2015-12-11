//
//  CloudKitDatabase.m
//  PrincetonRideShare
//
//  Created by Peter B Kramer on 10/23/15.
//  Copyright (c) 2015 Peter B Kramer. All rights reserved.
//

#import "CloudKitDatabase.h"

@interface CloudKitDatabase (){
    NSMutableDictionary *parameters;
 //   NSMutableDictionary *myInfoContents;
    int randomNumber;
    NSMutableArray *myMessages;
    NSDateFormatter *fullDateFormat;
    NSNumber *userRecordID;
    BOOL getFromItems;
}

@end


@implementation CloudKitDatabase

-(id)initWithParameters:(NSMutableDictionary *)theParameters{
    self = [super init];
    if (self) {
        parameters=theParameters;
        myMessages=[parameters objectForKey:@"MyMessages"];
        //myInfoContents=[[NSMutableDictionary alloc] initWithCapacity:1];
        int timeVariable=[NSDate timeIntervalSinceReferenceDate];
        randomNumber=abs((int)[[[[UIDevice currentDevice] identifierForVendor] UUIDString] hash])%10000000 +timeVariable%1000000;
        
        fullDateFormat=[[NSDateFormatter alloc] init];
        [fullDateFormat setDateFormat:@"MMM dd  h:mm:ss a"];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateRides:)
                                                     name:@"UpdateRides" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(messagesProcedures:)
                                                     name:@"MessagesProcedures" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(matchProcedures:)
                                                     name:@"MatchProcedures" object:nil];
        
    }
    return self;
}

-(void)setUpTheDatabases{
    [parameters setValue:[NSNumber numberWithBool:YES] forKey:@"iCloudAvailable"];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;  // presume it is available for a moment
    [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
        if (accountStatus == CKAccountStatusNoAccount) {
            [self iCloudErrorMessage:@"Unable to access iCloud.\nThis app uses iCloud for data storage and as a database.  Please activate your iCloud Account for this app otherwise you will not be able to store your Rides or send and receive Messages.  To activate your iCloud Account for this app, launch the Settings App, tap \"iCloud\", and enter your Apple ID.  Then turn \"iCloud Drive\" on and allow this App to store data.\nIf you don't have an iCloud account, tap \"Create a new Apple ID\"." ];
            [parameters setValue:[NSNumber numberWithBool:NO] forKey:@"iCloudAvailable"];
        }else if([[parameters objectForKey:@"VersionNumber"] isEqualToString:@"1.1"]){   //  it is version 1.1
            [parameters setValue:[NSNumber numberWithBool:NO] forKey:@"iCloudAvailable"];
            [self setUpTheDatabasesForVersion11];
        }else{
            [self setUpTheDatabasesForVersion12];   // also if version 1.3
        }
    }];
}

-(void)setUpTheDatabasesForVersion11{
    if([[parameters objectForKey:@"iCloudRecordID"] intValue]==0){
        [self setCurrentVersionNumber];
        [self setUpTheDatabasesForVersion12];
    }else{   //
        CKContainer *defaultContainer=[CKContainer defaultContainer];
        CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
    
        
        // so here the version 11 is already set up, need to create a version12
        
        CKFetchRecordsOperation *getUserRecord=[CKFetchRecordsOperation fetchCurrentUserRecordOperation];
        getUserRecord.perRecordCompletionBlock=^( CKRecord *record, CKRecordID *recordID, NSError *error){
            if(error){ // a bad error
                [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an iCloud error trying to access your database.  Please try again later.\n\n (%@)",error]];
            }else if([record objectForKey:@"iCloudRecordID"]){  // already set up by a different device using this same iCloud Account
                userRecordID=[record objectForKey:@"iCloudRecordID"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *loseMessages=@" lose all of the Messages that are stored on this device and";
                    if([[[parameters objectForKey:@"MyMessages"] objectAtIndex:0] isKindOfClass:[NSString class]])
                        loseMessages=@"";
                    NSString *loseRides=@"";
                    if([[parameters objectForKey:@"UpdateTheseRides"] count]>0){
                        loseRides=@" lose all of the Rides that are stored on this device.";
                    }else{
                        for(int I=0;I<=4;I++){
                            if([[[parameters objectForKey:@"TheRides"] objectAtIndex:I] objectForKey:@"GeoA"]) loseRides=@" lose all of the Rides that are stored on this device.";  /// perhaps should look for anything not nil
                        }
                    }
                    if(loseRides.length+loseMessages.length>2){
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Caution - Already Initialized" message:[NSString stringWithFormat:@"You have already initialized your iCloud database from a different device logged into this iCloud Account.  If you proceed with this device under this same iCloud Account then you will %@%@",loseMessages,loseRides]
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
                            
                            // what do I need to nil here?  IT depends on downloadFromDb actions.
                            //    this is stepping into another's db.  Download their messages and add them to these messages.
                            //     download all of the rides. and override any rides stored here.  since token is nil, that will happen
                            //     download all the messages - but they need to be zeroed here since its additive.
                            
                            
                            [[parameters objectForKey:@"UpdateTheseRides"] removeAllObjects];
                            [[parameters objectForKey:@"MyMessages"] removeAllObjects];
                            [[parameters objectForKey:@"MyMessages"] addObject:@"No messages"];
                            [self downloadFromDb];
                            
                        }]];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                            [self iCloudErrorMessage:[NSString stringWithFormat: @"You chose to cancel activation of iCloud under this iCloud Account.  Please activate iCloud under this or another iCloud Account for this app otherwise you will not be able to store your Rides or send and receive Messages." ]];
                            
                        }]];
                        [[[UIApplication sharedApplication]keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
                    }else{
                        [self downloadFromDb];  // there are no messages or rides stored locally.  this is v1.1 so token is nil
                    }
                });
            }else{
                [record setObject:[parameters objectForKey:@"iCloudRecordID"] forKey:@"iCloudRecordID"];
                
                CKModifyRecordsOperation *modifyRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:[NSArray arrayWithObject:record] recordIDsToDelete:nil];
                modifyRecords.qualityOfService=NSQualityOfServiceUserInitiated;
                modifyRecords.savePolicy=CKRecordSaveAllKeys;
                modifyRecords.modifyRecordsCompletionBlock=^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
                    if(operationError){
                        [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an iCloud error trying to save your ID to your database.  Please try again later.\n\n (%@)",error]];
                    }else{
                        [self initializePrivateDataBase];
                    }
                };
                [publicDatabase addOperation:modifyRecords];
            }
        };
        [publicDatabase addOperation:getUserRecord];
        
        /*
        //myinfo
        CKRecordID *myInfo = [[CKRecordID alloc] initWithRecordName:@"MyInfo"];
        [privateDatabase fetchRecordWithID:myInfo completionHandler:^(CKRecord *myInfoRecord, NSError *error) {
            if([error code]==CKErrorUnknownItem){  // no private database yet, create it
                [self initializePrivateDataBase];
                // there already is a public database so don't need to initialize it
            }else if(error){ // a bad error
                [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an iCloud error trying to access your database.  Please try again later.\n\n (%@)",error]];
            }else{  // already have myInfoRecord in private database
                
                [myInfoContents setObject:[myInfoRecord objectForKey:@"iCloudRecordID"] forKey:@"iCloudRecordID"];
         //       [myInfoContents setObject:[myInfoRecord objectForKey:@"SubscriptionSwitch"] forKey:@"SubscriptionSwitch"];
        //        [myInfoContents setObject:[myInfoRecord objectForKey:@"UnreadDateDList"] forKey:@"UnreadDateDList"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *loseMessages=@" lose all of the Messages that are stored on this device and";
                    if([[[parameters objectForKey:@"MyMessages"] objectAtIndex:0] isKindOfClass:[NSString class]])
                        //@"No messages"
                        loseMessages=@"";
                    NSString *loseRides=@"";
                   
                    if([[parameters objectForKey:@"UpdateTheseRides"] count]>0){
                        loseRides=@" lose all of the Rides that are stored on this device.";
                    }else{
                        for(int I=0;I<=4;I++){
                            if([[[parameters objectForKey:@"TheRides"] objectAtIndex:I] objectForKey:@"GeoA"]) loseRides=@" lose all of the Rides that are stored on this device.";  /// perhaps should look for anything not nil
                        }
                    }
                    if(loseRides.length+loseMessages.length>2){
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Caution - Already Initialized" message:[NSString stringWithFormat:@"You have already initialized your iCloud database from a different device logged into this iCloud Account.  If you proceed with this device under this same iCloud Account then you will %@%@",loseMessages,loseRides]
                            preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
                            
                            // what do I need to nil here?  IT depends on downloadFromDb actions.
                            //    this is stepping into another's db.  Download their messages and add them to these messages.
                            //     download all of the rides. and override any rides stored here.  since token is nil, that will happen
                            //     download all the messages - but they need to be zeroed here since its additive.
                            //    what about MyInfo - we already got it!!!!
                            
                            
                            [[parameters objectForKey:@"UpdateTheseRides"] removeAllObjects];
                            [[parameters objectForKey:@"MyMessages"] removeAllObjects];
                            [[parameters objectForKey:@"MyMessages"] addObject:@"No messages"];
                            [self downloadFromDb];
                            
                        }]];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                            [self iCloudErrorMessage:[NSString stringWithFormat: @"You chose to cancel activation of iCloud under this iCloud Account.  Please activate iCloud under this or another iCloud Account for this app otherwise you will not be able to store your Rides or send and receive Messages." ]];
                            
                        }]];
                        [[[UIApplication sharedApplication]keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
                    }else{
                        [self downloadFromDb];  // there are no messages or rides stored locally.  this is v1.1 so token is nil
                    }
                    
                });
            }
        }];
        
        
        */
    }
}


-(void)setUpTheDatabasesForVersion12{

 //   NSLog(@"setupthedatabasesforversion12");
    CKContainer *defaultContainer=[CKContainer defaultContainer];
    CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
    CKDatabase *privateDatabase=[defaultContainer privateCloudDatabase];
    CKFetchRecordsOperation *getUserRecord=[CKFetchRecordsOperation fetchCurrentUserRecordOperation];
    getUserRecord.perRecordCompletionBlock=^( CKRecord *record, CKRecordID *recordID, NSError *error){
        if(error){ // a bad error
            [parameters setValue:[NSNumber numberWithBool:NO] forKey:@"iCloudAvailable"];
            [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an iCloud error trying to access your database.  Please try again later.\n\n (%@)",error]];
        }else if(![record objectForKey:@"iCloudRecordID"]){  //   but what about myInfo???
            CKRecordID *myInfo = [[CKRecordID alloc] initWithRecordName:@"MyInfo"];
            [privateDatabase fetchRecordWithID:myInfo completionHandler:^(CKRecord *myInfoRecord, NSError *error) {
                if([error code]==CKErrorUnknownItem){  // no myInfo record, no value in userRecord
                    [parameters setValue:[NSNumber numberWithBool:NO] forKey:@"iCloudAvailable"];
                    if([[parameters objectForKey:@"iCloudRecordID"] intValue]==0){ //new device and new icloud account
                        [self getNewIDAndInitializeDb:0];
                    }else{    // device had icloud account set up, now a different icloud account
                        [self switchiCloudAccountsAlert:@"create a new"];
                    }
                }else if(error) {
                    //bad error
                    [parameters setValue:[NSNumber numberWithBool:NO] forKey:@"iCloudAvailable"];
                    [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an iCloud error trying to access your database.  Please try again later.\n\n (%@)",error]];
                }else{     //  there was a myInfo value! push it to userRecord and proceed
                    userRecordID=[myInfoRecord objectForKey:@"iCloudRecordID"];
                    [record setObject:userRecordID forKey:@"iCloudRecordID"];
                    NSArray *theRecordsToSave=[NSArray arrayWithObject:record];
                    CKModifyRecordsOperation *modifyRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:theRecordsToSave recordIDsToDelete:nil];
                    modifyRecords.savePolicy=CKRecordSaveAllKeys;
                    modifyRecords.qualityOfService=NSQualityOfServiceUserInitiated;
                    modifyRecords.modifyRecordsCompletionBlock=^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
                        if(operationError){
                            [parameters setValue:[NSNumber numberWithBool:NO] forKey:@"iCloudAvailable"];
                            [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an error trying to initialize your new database.  Please try again later. (%@)",operationError]];
                        }else{
                            [self startWithTheUserRecordID];
                        }
                    };
                    //   NSLog(@"and here is the complete set just befiore add operation  %@",theRecordsToSave);
                    [publicDatabase addOperation:modifyRecords];
                    
                }
            }];
        }else{
            userRecordID=[record objectForKey:@"iCloudRecordID"];
            [self startWithTheUserRecordID];
        }
    };
    [publicDatabase addOperation:getUserRecord];
    
    
    
        /*
        
    CKRecordID *myInfo = [[CKRecordID alloc] initWithRecordName:@"MyInfo"];
    [privateDatabase fetchRecordWithID:myInfo completionHandler:^(CKRecord *myInfoRecord, NSError *error) {
        if([error code]==CKErrorUnknownItem){  // no private database yet, create it
            [parameters setValue:[NSNumber numberWithBool:NO] forKey:@"iCloudAvailable"];
            if([[parameters objectForKey:@"iCloudRecordID"] intValue]==0){
                [self getNewIDAndInitializeDb:0];
            }else{
                [self switchiCloudAccountsAlert:@"create a new"];
            }
        }else if(error) {
            //bad error
            [parameters setValue:[NSNumber numberWithBool:NO] forKey:@"iCloudAvailable"];
            [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an iCloud error trying to access your database.  Please try again later.\n\n (%@)",error]];
        }else{
            [myInfoContents setObject:[myInfoRecord objectForKey:@"iCloudRecordID"] forKey:@"iCloudRecordID"];
       //     [myInfoContents setObject:[myInfoRecord objectForKey:@"SubscriptionSwitch"] forKey:@"SubscriptionSwitch"];
            
      //      if([myInfoRecord objectForKey:@"UnreadDateDList"] ){  // needed because of "UnreadList"
      //          [myInfoContents setObject:[myInfoRecord objectForKey:@"UnreadDateDList"] forKey:@"UnreadDateDList"];
      //      }else{
      //          [myInfoContents setObject:[[NSArray alloc] init] forKey:@"UnreadDateDList"];
      //      }
            
            if([[parameters objectForKey:@"iCloudRecordID"] isEqualToNumber:[myInfoRecord objectForKey:@"iCloudRecordID"]]){  // normal start
                NSLog(@"setup going forward");
                if([[parameters objectForKey:@"UpdateTheseRides"] count]>0){
                    [self askAboutRideChanges];
                }else{
                    [self downloadFromDb];
                }
            }else if([[parameters objectForKey:@"iCloudRecordID"] intValue]==0){
                [parameters setValue:[NSNumber numberWithBool:NO] forKey:@"iCloudAvailable"];
                // local id is 0 but the cloud has already been set up by a different device (e.g. new iPhone)
                //   the tokens are all nil since it is first time
                if([[parameters objectForKey:@"UpdateTheseRides"] count]>0){
                    [self askAboutRideChanges];
                }else{
                    [self downloadFromDb];
                }
            }else{
                //   local id# is not equal to id # in private db
                [parameters setValue:[NSNumber numberWithBool:NO] forKey:@"iCloudAvailable"];
                [self switchiCloudAccountsAlert:@"switch to the"];
            }
        }
    }];*/
}

-(void)startWithTheUserRecordID{
    if([[parameters objectForKey:@"iCloudRecordID"] isEqualToNumber:userRecordID]){  // normal start
    //    NSLog(@"setup going forward");
        if([[parameters objectForKey:@"UpdateTheseRides"] count]>0){
            [self askAboutRideChanges];
        }else{
            [self downloadFromDb];
        }
    }else if([[parameters objectForKey:@"iCloudRecordID"] intValue]==0){
        [parameters setValue:[NSNumber numberWithBool:NO] forKey:@"iCloudAvailable"];
        // local id is 0 but the cloud has already been set up by a different device (e.g. new iPhone)
        //   the tokens are all nil since it is first time
        if([[parameters objectForKey:@"UpdateTheseRides"] count]>0){
            [self askAboutRideChanges];
        }else{
            [self downloadFromDb];
        }
    }else{
        //   local id# is not equal to id # in private db
        [parameters setValue:[NSNumber numberWithBool:NO] forKey:@"iCloudAvailable"];
        [self switchiCloudAccountsAlert:@"switch to the"];
    }
}

-(void)askAboutRideChanges{
  //  NSLog(@"askaboutridechanges");
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"Changes To Rides"
                                    message:[NSString stringWithFormat:@"You have made changes to the Rides on this device that have not been saved to iCloud.  Do you want to save them to iCloud or discard them?"]
                                    preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            [parameters setValue:[NSNumber numberWithBool:YES] forKey:@"iCloudAvailable"];
            [[parameters objectForKey:@"UpdateTheseRides"] addObject:@"Call downloadFromDb when done"];
            [self updateRides:nil];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Discard" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
            [[parameters objectForKey:@"UpdateTheseRides"] removeAllObjects];
            [parameters removeObjectForKey:@"RidesToken"];
            [self downloadFromDb];
        }]];
        
        [[[UIApplication sharedApplication]keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
    });
    
    
    
    
    
}


-(void)switchiCloudAccountsAlert:(NSString *)condition{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *andRides=@"";
        if([condition isEqualToString:@"switch to the"])andRides=@" and Rides";
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"Change iCloud Account?"
                                    message:[NSString stringWithFormat:@"You seem to have changed iCloud Accounts.  Do you want to %@ database under this changed iCloud Account and access it?  If you do, the Messages%@ currently stored on this device will not be transferred.",condition,andRides]
                                    preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            [[parameters objectForKey:@"MyMessages"] removeAllObjects];
            [[parameters objectForKey:@"MyMessages"] addObject:@"No messages"];
            if([condition isEqualToString:@"switch to the"]){
                
                [[parameters objectForKey:@"UpdateTheseRides"] removeAllObjects];
                
                [parameters removeObjectForKey:@"RidesToken"];
                [parameters removeObjectForKey:@"MessagesToken"];
                [self downloadFromDb];
            }else{
                // [parameters setObject:[NSNumber numberWithLong:0] forKey:@"iCloudRecordID"];
                [self getNewIDAndInitializeDb:0];
            }
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"No, cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
            [self iCloudErrorMessage:[NSString stringWithFormat: @"You chose to cancel accessing iCloud under your current iCloud Account.  Please activate iCloud under this or another iCloud Account for this app otherwise you will not be able to store your Rides or send and receive Messages." ]];
            
        }]];
        [[[UIApplication sharedApplication]keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
    });
}



-(void)updateRides:(NSNotification *)notification{
    
 //   NSLog(@"updaterides .....");
    
    [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
        if (accountStatus == CKAccountStatusNoAccount || ![[parameters objectForKey:@"iCloudAvailable"] boolValue]){
            [self iCloudErrorMessage:[NSString stringWithFormat:@"iCloud is not available.  Your changes will be recorded the next time iCloud is available."]];
        }else {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            CKContainer *defaultContainer=[CKContainer defaultContainer];
            
            NSArray *theKeys=[NSArray arrayWithObjects:@"ArriveEnd",@"ArriveStart",@"LeaveEnd",@"LeaveStart",@"DaysOfTheWeek",@"MyCarOrYours",@"GeoA",@"GeoAlat",@"GeoB",@"GeoBlat",nil];
            
            int recordID=[[parameters objectForKey:@"iCloudRecordID"] intValue];
            
            //   but it might be a change through askAboutRideChanges when starting this device but before downloadFromDB if this device is not first device using this iCloud Account....
         //   if (recordID==0) recordID=[[myInfoContents objectForKey:@"iCloudRecordID"] intValue];
            if (recordID==0) recordID=[userRecordID intValue];
            
            
            
            
            CKDatabase *privateDatabase=[defaultContainer privateCloudDatabase];
            CKRecordZoneID *ridesZoneID=[[CKRecordZoneID alloc] initWithZoneName:@"RidesZone" ownerName:CKOwnerDefaultName];
            NSMutableArray *theRecordsToSaveArray=[[NSMutableArray alloc] initWithCapacity:5];
            CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
            NSMutableArray *theNoZoneRecordsToSaveArray=[[NSMutableArray alloc] initWithCapacity:5];
            NSMutableArray *theNoZoneRecordsToDeleteArray=[[NSMutableArray alloc] initWithCapacity:5];
            
            
            for(long I=1;I<=5;I++){
                if([[parameters objectForKey:@"UpdateTheseRides"] containsObject:[NSNumber numberWithLong:I-1]]){
                    
                    int ride=(int)I;
                    
                 //   NSLog(@"UPDATE ride %li",I);
                    
                    CKRecordID *aCKRecordID=[[CKRecordID alloc] initWithRecordName:[NSString stringWithFormat:@"%i%i",recordID,ride] zoneID:ridesZoneID];
                    CKRecord *aRecord=[[CKRecord alloc] initWithRecordType:@"Rides" recordID:aCKRecordID];
                    CKRecordID *aCKRecordIDNoZone=[[CKRecordID alloc] initWithRecordName:[NSString stringWithFormat:@"%i%i",recordID,ride]];
                    CKRecord *aRecordNoZone=[[CKRecord alloc] initWithRecordType:@"Rides" recordID:aCKRecordIDNoZone];
                    
                    NSDictionary *aRide=[[parameters objectForKey:@"TheRides"] objectAtIndex:ride-1];
                    for(int J=0;J<[theKeys count];J++){
                        NSString *key=[theKeys objectAtIndex:J];
                        [aRecord setObject:[aRide objectForKey:key] forKey:key];
                        [aRecordNoZone setObject:[aRide objectForKey:key] forKey:key];
                    }
                    [aRecord setObject:[NSNumber numberWithInt:recordID*10+ride] forKey:@"IDNumber"];
                    [aRecord setObject:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"TheDateLastAccessed"];  // an nsdate object
                    [aRecord setObject:[fullDateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]] forKey:@"Title"];
                    [theRecordsToSaveArray addObject:aRecord];
                    if([aRide objectForKey:@"GeoA"]){
                        [aRecordNoZone setObject:[NSNumber numberWithInt:recordID*10+ride] forKey:@"IDNumber"];
                        [aRecordNoZone setObject:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"TheDateLastAccessed"];  // an nsdate object
                        [aRecordNoZone setObject:[fullDateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]] forKey:@"Title"];
                        CLLocation *home=[[CLLocation alloc] initWithLatitude:[[aRide objectForKey:@"GeoAlat"] doubleValue] longitude:[[aRide objectForKey:@"GeoA"] doubleValue]];
                        [aRecordNoZone setObject:home forKey:@"HomeLocation"];  // a CLLocation object
                        [theNoZoneRecordsToSaveArray addObject:aRecordNoZone];
                    }else{
                        [theNoZoneRecordsToDeleteArray addObject:aCKRecordIDNoZone];
                    }
                    
                }
            }
            
            
            __block BOOL otherDatabaseHasEnded=NO;
            CKModifyRecordsOperation *modifyRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:theRecordsToSaveArray recordIDsToDelete:nil];
            modifyRecords.qualityOfService=NSQualityOfServiceUserInitiated;
            modifyRecords.savePolicy=CKRecordSaveAllKeys;
            modifyRecords.modifyRecordsCompletionBlock=^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
                if(operationError){
                    if(operationError.code==CKErrorPartialFailure){
                     //   NSLog(@"a partial error?????  WHAT DO I DO???? aaa %@",operationError);
                        //operationError=nil;
                    }
                }
                if(operationError){
                    int seconds=0;
                    if(operationError.code==CKErrorServiceUnavailable || operationError.code==CKErrorRequestRateLimited)
                        seconds=[[[operationError userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                    if(seconds>0){
                        [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to save Rides.  Please try again after %i seconds.\n\n(%@)",seconds,operationError]];
                    }else{
                        //     NSLog(@"the error was  %@",operationError);
                        [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an iCloud error trying to save Rides.  Please try again later.\n\n (%@)",operationError]];
                    }
                }else if(otherDatabaseHasEnded){
              //      NSLog(@"executed in private database");
                    //    NSLog(@"saved these records:  %@",savedRecords);
                    if([[parameters objectForKey:@"UpdateTheseRides"] containsObject:@"Call downloadFromDb when done"])[self downloadFromDb];
                    [[parameters objectForKey:@"UpdateTheseRides"] removeAllObjects];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    });
                }else{
                    
                  //  NSLog(@"executed in private database earlier");
                }
                otherDatabaseHasEnded=YES;
            };
            
            
            CKModifyRecordsOperation *modifyPublicRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:theNoZoneRecordsToSaveArray recordIDsToDelete:theNoZoneRecordsToDeleteArray];
            modifyPublicRecords.savePolicy=CKRecordSaveAllKeys;
            modifyPublicRecords.qualityOfService=NSQualityOfServiceUserInitiated;
            modifyPublicRecords.modifyRecordsCompletionBlock=^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
                if(operationError){
                    if(operationError.code==CKErrorPartialFailure){
                   //     NSLog(@"a partial error?????  WHAT DO I DO???? bbb %@",operationError);
                        //operationError=nil;
                    }
                }
                if(operationError){
                    int seconds=0;
                    if(operationError.code==CKErrorServiceUnavailable || operationError.code==CKErrorRequestRateLimited)
                        seconds=[[[operationError userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                    if(seconds>0){
                        [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to save Rides to the Public Database.  Please try again after %i seconds.\n\n(%@)",seconds,operationError]];
                    }else{
                        //     NSLog(@"the error was  %@",operationError);
                        [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an iCloud error trying to save Rides to the Public Database.  Please try again later.\n\n (%@)",operationError]];
                    }
                }else if(otherDatabaseHasEnded){
                  //  NSLog(@"executed in public database");
                    //    NSLog(@"saved these records:  %@",savedRecords);
                    if([[parameters objectForKey:@"UpdateTheseRides"] containsObject:@"Call downloadFromDb when done"])[self downloadFromDb];
                    [[parameters objectForKey:@"UpdateTheseRides"] removeAllObjects];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    });
                }else{
                //    NSLog(@"executed in public database earlier");
                }
                otherDatabaseHasEnded=YES;
            };
            
            
            [privateDatabase addOperation:modifyRecords];
            [publicDatabase addOperation:modifyPublicRecords];
            
            
        }
    }];
}




-(void)addRecordsOfRidesTo:(NSMutableArray *)theRecordsToSave addHome:(BOOL)home{
    NSArray *theKeys=[NSArray arrayWithObjects:@"ArriveEnd",@"ArriveStart",@"LeaveEnd",@"LeaveStart",@"DaysOfTheWeek",@"MyCarOrYours",@"GeoA",@"GeoAlat",@"GeoB",@"GeoBlat",nil];
    int recordID=[[parameters objectForKey:@"iCloudRecordID"] intValue];
    CKRecordZoneID *ridesZoneID=[[CKRecordZoneID alloc] initWithZoneName:@"RidesZone" ownerName:CKOwnerDefaultName];
    
    
  //  NSLog(@"adding a ride in its zone");
    
    
    for(int I=1;I<=5;I++){
        NSDictionary *aRide=[[parameters objectForKey:@"TheRides"] objectAtIndex:I-1];
        if(!home || [aRide objectForKey:@"GeoA"]){
            CKRecordID *aCKRecordId;
            if(home){
                aCKRecordId=[[CKRecordID alloc] initWithRecordName:[NSString stringWithFormat:@"%i%i",recordID,I]];
            }else{
                aCKRecordId=[[CKRecordID alloc] initWithRecordName:[NSString stringWithFormat:@"%i%i",recordID,I] zoneID:ridesZoneID];
              //  NSLog(@"adding the zone");
            }
            CKRecord *aRecord=[[CKRecord alloc] initWithRecordType:@"Rides" recordID:aCKRecordId];
    
            for(int J=0;J<[theKeys count];J++){
                NSString *key=[theKeys objectAtIndex:J];
                [aRecord setObject:[aRide objectForKey:key] forKey:key];
            }
            [aRecord setObject:[NSNumber numberWithInt:recordID*10+I] forKey:@"IDNumber"];
            [aRecord setObject:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"TheDateLastAccessed"];  // an nsdate object
            [aRecord setObject:[fullDateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]] forKey:@"Title"];
            if(home){
                CLLocation *home=[[CLLocation alloc] initWithLatitude:[[aRide objectForKey:@"GeoAlat"] doubleValue] longitude:[[aRide objectForKey:@"GeoA"] doubleValue]];
                [aRecord setObject:home forKey:@"HomeLocation"];  // a CLLocation object
            }
            [theRecordsToSave addObject:aRecord];
        }
    }
}

-(void)addTheseMessages:(NSArray *)messageArray toRecordsToSave:(NSMutableArray *)theRecordsToSave{
    //  note - messageArray could contain nsdictionaries or ckrecords
    
    
    CKRecordZoneID *messageZoneID=[[CKRecordZoneID alloc] initWithZoneName:@"MessageZone" ownerName:CKOwnerDefaultName];
    for(int I=0;I<[messageArray count];I++){
        CKRecordID *aCKRecordId=[[CKRecordID alloc] initWithRecordName: //@"a name here" ];
                                 [NSString stringWithFormat:@"%@ to %@ on %@",
                                  [[messageArray objectAtIndex:I] objectForKey:@"From"],
                                  [[messageArray objectAtIndex:I] objectForKey:@"ToNumber"],
                                  [fullDateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:[[[messageArray objectAtIndex:I] objectForKey:@"DateD"] doubleValue]]]] zoneID:messageZoneID];
        CKRecord *aMessage=[[CKRecord alloc] initWithRecordType:@"Messages" recordID:aCKRecordId];
        [aMessage setObject:[[messageArray objectAtIndex:I] objectForKey:@"ToNumber"]  forKey:@"ToNumber"];
        [aMessage setObject:[[messageArray objectAtIndex:I] objectForKey:@"ToRide"]  forKey:@"ToRide"];
        [aMessage setObject:[[messageArray objectAtIndex:I] objectForKey:@"FromRide"]  forKey:@"FromRide"];
        [aMessage setObject:[[messageArray objectAtIndex:I] objectForKey:@"From"]  forKey:@"From"];
        [aMessage setObject:[[messageArray objectAtIndex:I] objectForKey:@"Message"]  forKey:@"Message"];
        [aMessage setObject:[[messageArray objectAtIndex:I] objectForKey:@"DateD"]  forKey:@"DateD"];
        [aMessage setObject:[[messageArray objectAtIndex:I] objectForKey:@"Title"]  forKey:@"Title"];
        
        [theRecordsToSave addObject:aMessage];
    }
}

/*
-(void)addTheseMessages:(NSArray *)messageArray toUnreadList:(NSMutableArray *) theUnreadList{
    
    NSLog(@"the message array is %@",messageArray);
        
    if([[messageArray objectAtIndex:0] isKindOfClass:[NSDictionary class]]){
        
            for(int I=0;I<[messageArray count];I++){
                NSLog(@"the I is %i",I);
            NSDictionary *aMessageToUpload=[messageArray objectAtIndex:I];
            //      it could be just downloaded from the public database in which case this is nil
            //   it could be a to message - "Just downloaded"
            //    it could be a from message   "No"
            if(![aMessageToUpload objectForKey:@"Read"]){
                [theUnreadList addObject:[aMessageToUpload objectForKey:@"DateD"]];
            }else if([[aMessageToUpload objectForKey:@"Read"] isEqualToString:@"Just downloaded"]||  [[aMessageToUpload objectForKey:@"Read"] isEqualToString:@"No"]){
                [theUnreadList addObject:[aMessageToUpload objectForKey:@"DateD"]];
            }
        }
    }else if([[messageArray objectAtIndex:0] isKindOfClass:[CKRecord class]]){
        for(int I=0;I<[messageArray count];I++){
            CKRecord *aMessageToUpload=[messageArray objectAtIndex:I];
            if(![aMessageToUpload objectForKey:@"Read"]){
                [theUnreadList addObject:[aMessageToUpload objectForKey:@"DateD"]];
            }else if([[aMessageToUpload objectForKey:@"Read"] isEqualToString:@"Just downloaded"]||  [[aMessageToUpload objectForKey:@"Read"] isEqualToString:@"No"]){
                [theUnreadList addObject:[aMessageToUpload objectForKey:@"DateD"]];
            }
        }
    }
}
*/

-(void)initializePrivateDataBase{
    // there may or may not be messages to upload.
    // any messages that are uploaded will be downloaded when getMessages is run because not setting the token
  //  NSLog(@"initalizing private database");
    CKContainer *defaultContainer=[CKContainer defaultContainer];
    CKDatabase *privateDatabase=[defaultContainer privateCloudDatabase];
 //   CKRecordID *myInfo = [[CKRecordID alloc] initWithRecordName:@"MyInfo"];
    NSMutableArray *messageArray=[parameters objectForKey:@"MyMessages"];
    NSMutableArray *theRecordsToSave=[[NSMutableArray alloc] initWithCapacity:[messageArray count]+5];
//    NSMutableArray *theUnreadList=[[NSMutableArray alloc] initWithCapacity:[messageArray count]];
    
    
    if(![[messageArray objectAtIndex:0] isKindOfClass:[NSString class]]){
        [self addTheseMessages:messageArray toRecordsToSave:theRecordsToSave];
     //   [self addTheseMessages:messageArray toUnreadList:theUnreadList];
    }
    
    [self addRecordsOfRidesTo:theRecordsToSave addHome:NO];
    
//    CKRecord *myInfoRecord=[[CKRecord alloc] initWithRecordType:@"Info" recordID:myInfo];
///    [myInfoRecord setObject:[parameters objectForKey:@"iCloudRecordID"] forKey:@"iCloudRecordID"];
    
    
  //  [myInfoRecord setObject:[parameters objectForKey:@"SubscriptionSwitch"] forKey:@"SubscriptionSwitch"];
 //   [myInfoRecord setObject:theUnreadList forKey:@"UnreadDateDList"];
 //   [theRecordsToSave addObject:myInfoRecord];
 //   NSLog(@"here is a record:  %@",myInfoRecord);
    
    
    NSArray *theRecordsToSaveArray=[NSArray arrayWithArray:theRecordsToSave];
    
    
    
    CKRecordZone *theRidesZone=[[CKRecordZone alloc] initWithZoneName:@"RidesZone"];
    CKRecordZone *theMessagesZone=[[CKRecordZone alloc] initWithZoneName:@"MessageZone"];
    CKModifyRecordZonesOperation *createZones=[[CKModifyRecordZonesOperation alloc] initWithRecordZonesToSave:[NSArray arrayWithObjects:theRidesZone,theMessagesZone,nil] recordZoneIDsToDelete:nil];
    createZones.qualityOfService=NSQualityOfServiceUserInitiated;
    createZones.modifyRecordZonesCompletionBlock=^(NSArray *savedRecordZones, NSArray *deletedRecordZones, NSError *operation1Error){
        if(operation1Error){
           // NSLog(@"error in setting up the zone  %@",operation1Error);
        //operationError=nil;
        }else{
          //  NSLog(@"the zone was set up");
        }
        
        
        
        CKModifyRecordsOperation *modifyRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:theRecordsToSaveArray recordIDsToDelete:nil];
        modifyRecords.savePolicy=CKRecordSaveAllKeys;
        modifyRecords.qualityOfService=NSQualityOfServiceUserInitiated;
        modifyRecords.modifyRecordsCompletionBlock=^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
            if(operationError){
                if(operationError.code==CKErrorPartialFailure){
                  //  NSLog(@"a partial error?????  WHAT DO I DO????  %@",operationError);
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
                    [[parameters objectForKey:@"MyMessages"] addObject:@"No messages"];
                    [[parameters objectForKey:@"UpdateTheseRides"] removeAllObjects]; // uploaded when created
                    [parameters setValue:[NSNumber numberWithBool:YES] forKey:@"iCloudAvailable"];
                    [self setCurrentVersionNumber];//success (might be v1.1)
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                });
            }
        };
        [privateDatabase addOperation:modifyRecords];
        
    };
    [privateDatabase addOperation:createZones];
    
}



-(void)initializePublicDatabase{
    
 //   NSLog(@"initalizing public database");
    
    CKContainer *defaultContainer=[CKContainer defaultContainer];
    CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
    CKFetchRecordsOperation *getUserRecord=[CKFetchRecordsOperation fetchCurrentUserRecordOperation];
    getUserRecord.perRecordCompletionBlock=^( CKRecord *record, CKRecordID *recordID, NSError *error){
        if(error){
            [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an error trying to initialize your database record.  Please try again later. (%@)",error]];
        }else{
            NSMutableArray *theRecordsToSave=[[NSMutableArray alloc] initWithCapacity:6];
            [record setObject:[parameters objectForKey:@"iCloudRecordID"] forKey:@"iCloudRecordID"];
            [theRecordsToSave addObject:record];
            int I=0;
            CKRecord *zerothRecord=[[CKRecord alloc] initWithRecordType:@"Rides" recordID:[[CKRecordID alloc] initWithRecordName:[NSString stringWithFormat:@"%i%i",[[parameters objectForKey:@"iCloudRecordID"] intValue],I]]];
            
            [theRecordsToSave addObject:zerothRecord];
            
            [self addRecordsOfRidesTo:theRecordsToSave addHome:YES];
            
            CKModifyRecordsOperation *modifyRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:theRecordsToSave recordIDsToDelete:nil];
            modifyRecords.savePolicy=CKRecordSaveAllKeys;
            modifyRecords.qualityOfService=NSQualityOfServiceUserInitiated;
            modifyRecords.modifyRecordsCompletionBlock=^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
                if(operationError){
                    if(operationError.code==CKErrorPartialFailure){
                      //  NSLog(@"a partial error?????    %@",operationError);
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
                    [parameters setObject:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"TimeOfLastUpdate"];
                    [self initializePrivateDataBase];
                }
            };
            //   NSLog(@"and here is the complete set just befiore add operation  %@",theRecordsToSave);
            [publicDatabase addOperation:modifyRecords];
        }
    };
    [publicDatabase addOperation:getUserRecord];
}







-(void)getNewIDAndInitializeDb:(int)trialNumber{

    CKContainer *defaultContainer=[CKContainer defaultContainer];
    CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
    
    srandom(randomNumber);
    randomNumber= abs( (int)random());
    randomNumber=randomNumber%10000000;
    if(randomNumber<1000000)randomNumber=randomNumber+1000000;
    //  between 1,000,000 and 9,999,999
    NSString *trialRecordIDName=[NSString stringWithFormat:@"%i0",randomNumber];
    CKRecordID *trialRecordID=[[CKRecordID alloc] initWithRecordName:trialRecordIDName];
    [publicDatabase fetchRecordWithID:trialRecordID completionHandler:^(CKRecord *fetchedRecord, NSError *error){
        if([error code]==CKErrorUnknownItem){  //  no such record exists, create it
            // NOT AN ERROR
            [parameters setObject:[NSNumber numberWithInt:randomNumber] forKey:@"iCloudRecordID"];
            [parameters removeObjectForKey:@"MessagesToken"];
            [parameters removeObjectForKey:@"RidesToken"];
            
            
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateIntroPage" object:nil];
            
            
            // redo tab Intro
            
            
            
            
            
            //            NSLog(@"got a valid recordID");
            // [self getInitialSubscription];
            
   // put this in the next method at success
        //[self initializePrivateDataBase];
            
         //   NSLog(@"going forward with   %i",randomNumber);
            
            [self initializePublicDatabase];
            
        }else if (!error){
            //     NSLog(@"trying a new number");
            if(trialNumber<4){
                [self getNewIDAndInitializeDb:trialNumber+1];// try a new random number for the trialRecordID
            }else{
                [self iCloudErrorMessage:[NSString stringWithFormat: @"Having trouble finding a unique iCloud Drive ID.  Please try again later."]];
            }
        }else{
            // NSLog(@"error in icloud 3745947");
            [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an error (2) trying to initialize your database.  Please try again later by restarting this app. (%@)",error]];
        }
    }];
    
}




-(void)downloadFromDb{   // note - not on main thread
    
    // messages will be downloaded when the message tab is tapped.
    
  //  NSLog(@"downloadfromdb");
    [self setCurrentVersionNumber];//success (might be v1.1)  whether or not we get the rides
    
    
    
  /*  if(![[parameters objectForKey:@"iCloudRecordID"] isEqualToNumber:[myInfoContents objectForKey:@"iCloudRecordID"]]){
        [parameters setObject:[myInfoContents objectForKey:@"iCloudRecordID"] forKey:@"iCloudRecordID"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateIntroPage" object:nil];
        });
    }*/
    BOOL updateIntroPage=NO;
    if([parameters objectForKey:@"iCloudRecordID"]){
        if(![[parameters objectForKey:@"iCloudRecordID"] isEqualToNumber:userRecordID])updateIntroPage=YES;
    }else{
        updateIntroPage=YES;
    }
    if(updateIntroPage){
        [parameters setObject:userRecordID forKey:@"iCloudRecordID"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateIntroPage" object:nil];
        });
    }
    
    
//    [parameters setObject:[myInfoContents objectForKey:@"SubscriptionSwitch"] forKey:@"SubscriptionSwitch"];
    
    
    [[[CKContainer defaultContainer] publicCloudDatabase]  fetchAllSubscriptionsWithCompletionHandler:^(NSArray *subscriptions, NSError *error) {
        if (error) {
           // NSLog(@"subscription switch error");
        } else {
            NSMutableArray *currentSubscriptionIDs=[[NSMutableArray alloc] initWithCapacity:[subscriptions count]];
            //    NSLog(@"THE SUBSCRIPTION COUNT IS %lu",(unsigned long)[subscriptions count]);
            NSString *subscriptionIDToAdd=[NSString stringWithFormat:@"%i",[[parameters objectForKey:@"iCloudRecordID"] intValue]] ;
            for (CKSubscription *subscription in subscriptions) {
                [currentSubscriptionIDs addObject:subscription.subscriptionID];
            }
            
            //NSLog(@"the arrays are %@    and %@",currentSubscriptionIDs,subscriptionIDToAdd);
            
            [parameters setObject:[NSNumber numberWithBool:[currentSubscriptionIDs containsObject:subscriptionIDToAdd]] forKey:@"SubscriptionSwitch"];
            
            dispatch_async(dispatch_get_main_queue(), ^{  // set the switch
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnFromCloud" object:@"SubscriptionSwitch"];
            });
            
            // register for notifications and issue an alert if necessary
            if([[parameters objectForKey:@"SubscriptionSwitch"] boolValue]){
                UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeBadge | UIUserNotificationTypeAlert;
                UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
                [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
                [[UIApplication sharedApplication] registerForRemoteNotifications];
               // NSLog(@"Registering");
            }
            
            [currentSubscriptionIDs removeObject:subscriptionIDToAdd];
            
            // NOTE - at this point "currentSubscriptionIDs" are the ones we want to remove
            
            if([currentSubscriptionIDs count]>0){
                CKModifySubscriptionsOperation *modifySubscriptions=[[CKModifySubscriptionsOperation alloc] initWithSubscriptionsToSave:nil subscriptionIDsToDelete:currentSubscriptionIDs]; // want to delete previous users of this device
                //       NSLog(@"the arguments are %@   %@",subscriptionToAdd,subscriptionToDelete);
                modifySubscriptions.qualityOfService=NSQualityOfServiceUserInitiated;
                modifySubscriptions.modifySubscriptionsCompletionBlock=^(NSArray * savedSubscriptions, NSArray * deletedSubscriptionIDs, NSError * operationError){
                    if(operationError){
                       // NSLog(@"the error was  %@",operationError);
                    }else{
                     //   NSLog(@"Subscribed succesfully - saved this subscription:  %@   and deleted this subscription:   %@",savedSubscriptions,deletedSubscriptionIDs);
                    }
                    
                };
                [[[CKContainer defaultContainer] publicCloudDatabase] addOperation:modifySubscriptions];
            }
        }
    }];

    [self fetchTheRides];

    
}

-(void)fetchTheRides{
    //fetch changed records
    NSArray *theKeys=[NSArray arrayWithObjects:@"ArriveEnd",@"ArriveStart",@"LeaveEnd",@"LeaveStart",@"DaysOfTheWeek",@"MyCarOrYours",@"GeoA",@"GeoAlat",@"GeoB",@"GeoBlat",@"TheDateLastAccessed",@"Title",nil];
    CKRecordZoneID *ridesZoneID=[[CKRecordZoneID alloc] initWithZoneName:@"RidesZone" ownerName:CKOwnerDefaultName];
    CKFetchRecordChangesOperation *getRides=[[CKFetchRecordChangesOperation alloc] initWithRecordZoneID:ridesZoneID previousServerChangeToken:[parameters objectForKey:@"RidesToken"]];
    __weak CKFetchRecordChangesOperation *weakGetRides=getRides;
    getRides.qualityOfService=NSQualityOfServiceUserInitiated;
    getRides.recordChangedBlock=^(CKRecord *aRide){
        int I=[[[aRide recordID] recordName] intValue]%10-1;
        if([[parameters objectForKey:@"TheRides"] count]>I && I>=0){
            NSMutableDictionary *aRecord=[[parameters objectForKey:@"TheRides"] objectAtIndex:I];
            for(int J=0;J<[theKeys count];J++){
                NSString *key=[theKeys objectAtIndex:J];
                if([aRide objectForKey:key]){
                    [aRecord setObject:[aRide objectForKey:key] forKey:key];
                }else{
                    [aRecord removeObjectForKey:key];
                }
            }
        }
      //  NSLog(@"just updated ride %i   %@",I,[[parameters objectForKey:@"TheRides"] objectAtIndex:I]);
    };
    getRides.fetchRecordChangesCompletionBlock=^(CKServerChangeToken *serverChangeToken, NSData *clientChangeTokenData, NSError *operationError){
        
        if(!weakGetRides.moreComing){  // i think we need to do this whether or not there is an error.
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"RidesWereUpdated" object:nil];
            });
        }
        
        if(operationError){
            [parameters setValue:[NSNumber numberWithBool:NO] forKey:@"iCloudAvailable"];
            if(operationError.code==26){  // needed only for devices that had run an earlier v1.2
              //  NSLog(@"zone not found - initializing");
                [self initializePrivateDataBase];
            }else{
                [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud error downloading your Rides.  (%@)",operationError]];
            }
        }else{
            if(serverChangeToken){
                [parameters setObject:serverChangeToken forKey:@"RidesToken"];
            }else{
                [parameters removeObjectForKey:@"RidesToken"];
            }
            
            
            // if not yet done, do it again and come back here.  Otherwise - proceed
            if(weakGetRides.moreComing){
                [self fetchTheRides];
            }else{
                [parameters setValue:[NSNumber numberWithBool:YES] forKey:@"iCloudAvailable"];
                
                //   update the public records so the date is the date the app was last used
                if([[parameters objectForKey:@"TimeOfLastUpdate"] timeIntervalSinceNow]<=-24*60*60){
                    CKContainer *defaultContainer=[CKContainer defaultContainer];
                    CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
                    NSMutableArray *theRecordsToSave=[[NSMutableArray alloc] initWithCapacity:6];
                    
                    int recordID=[[parameters objectForKey:@"iCloudRecordID"] intValue];
                    for(int I=1;I<=5;I++){
                        NSDictionary *aRide=[[parameters objectForKey:@"TheRides"] objectAtIndex:I-1];
                        if([aRide objectForKey:@"GeoA"]){
                            CKRecordID *aCKRecordId=[[CKRecordID alloc] initWithRecordName:[NSString stringWithFormat:@"%i%i",recordID,I]];
                            CKRecord *aRecord=[[CKRecord alloc] initWithRecordType:@"Rides" recordID:aCKRecordId];
                            [aRecord setObject:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"TheDateLastAccessed"];  // an nsdate object
                            [aRecord setObject:[fullDateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]] forKey:@"Title"];
                            [theRecordsToSave addObject:aRecord];
                        }
                    }
                    CKModifyRecordsOperation *modifyRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:theRecordsToSave recordIDsToDelete:nil];
                    modifyRecords.savePolicy=CKRecordSaveAllKeys;
                    modifyRecords.qualityOfService=NSQualityOfServiceUserInitiated;
                    modifyRecords.modifyRecordsCompletionBlock=^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
                        if(operationError){
                            if(operationError.code==CKErrorPartialFailure){
                              //  NSLog(@"a partial error?????    %@",operationError);
                                //operationError=nil;
                            }
                        }else{
                            [parameters setObject:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"TimeOfLastUpdate"];
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        });
                    };
                    //   NSLog(@"and here is the complete set just befiore add operation  %@",theRecordsToSave);
                    [publicDatabase addOperation:modifyRecords];
                    
                    
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    });
                }
            }
        }
    };
    [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:getRides];
}




-(void)getMyFromUnreadItems{
    CKContainer *defaultContainer=[CKContainer defaultContainer];
    CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
    NSPredicate *predicate1=[NSPredicate predicateWithFormat:@"From == %i",[[parameters objectForKey:@"iCloudRecordID"] intValue] ];
    CKQuery *query1=[[CKQuery alloc] initWithRecordType:@"Messages" predicate:predicate1];
    [publicDatabase performQuery:query1 inZoneWithID:nil completionHandler:
     ^(NSArray *results, NSError *error){
         if(error){
             if(error.code==CKErrorPartialFailure)error=nil;
         }
         if(error){
             dispatch_async(dispatch_get_main_queue(), ^{
                 [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             });
         }else{
             NSMutableArray *myFromDates=[[NSMutableArray alloc] initWithCapacity:[results count]];
             for(int I=0;I<[results count];I++){
                 if([[results objectAtIndex:I] objectForKey:@"DateD"]){
                     [myFromDates addObject:[[results objectAtIndex:I] objectForKey:@"DateD"]];
                 }
             }
             for(int I=0;I<[myMessages count];I++){  // mark the message as 'read'
                 //    NSLog(@"the message is   %@",[myMessages objectAtIndex:I] );
                 if([[myMessages objectAtIndex:I] isKindOfClass:[NSDictionary class]]){
                     if([[[myMessages objectAtIndex:I] objectForKey:@"Read"] isEqualToString:@"No"] ){
                         if(![myFromDates containsObject: [[myMessages objectAtIndex:I] objectForKey:@"DateD"]] ){
                             [[[myMessages objectAtIndex:I] objectForKey:@"Read"] setString:@"Yes"];
                         }
                     }else if([[[myMessages objectAtIndex:I] objectForKey:@"Read"] isEqualToString:@"Just saved"] ){
                            [[[myMessages objectAtIndex:I] objectForKey:@"Read"] setString:@"No"];
                     }
                 }
             }
             dispatch_async(dispatch_get_main_queue(), ^{
                 [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnFromCloud" object:nil];
             });
         }
     }];
}
-(void)matchProcedures:(NSNotification *)notification{
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    CKContainer *defaultContainer=[CKContainer defaultContainer];
 //   CKDatabase *privateDatabase=[defaultContainer privateCloudDatabase];
    CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
  //  NSLog(@"the notification object is %@",[notification object]);
    if ([[notification object] isKindOfClass:[NSString class]]) {  // "show matches" tapped from My Info
        NSMutableArray *recordIDs=[[NSMutableArray alloc] initWithCapacity:5];
        for (int I=0;I<=5;I++){
            [recordIDs addObject:[[CKRecordID alloc] initWithRecordName:[NSString stringWithFormat:@"%i%i",[[notification object] intValue],I]]];
        }
        CKFetchRecordsOperation *fetchRecords=[[CKFetchRecordsOperation alloc] initWithRecordIDs:recordIDs];
        fetchRecords.qualityOfService=NSQualityOfServiceUserInitiated;
        fetchRecords.fetchRecordsCompletionBlock= ^(NSDictionary *recordsByRecordID,NSError *error){
            if(error){
                if(error.code==CKErrorPartialFailure)error=nil;
            }
            if(error){
                int seconds=0;
                if(error.code==CKErrorServiceUnavailable || error.code==CKErrorRequestRateLimited)
                    seconds=[[[error userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                if(seconds>0){
                    [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue (1) trying to get the Match data.  Please try again after %i seconds.",seconds]];
                }else{
                    [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an error (1) trying to get the Match data.  Please try again later. (%@)",error]];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnWithMatches" object:@"Error"];
                });
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnWithMatches" object:recordsByRecordID];
                });
            }
        };
        [publicDatabase addOperation:fetchRecords];
    }else{
        NSDate *thirtyDaysAgo=[NSDate dateWithTimeIntervalSinceNow:-30*24*3600] ;
        //    float radiusInKilometers=5;
        CLLocation *home=[[CLLocation alloc] initWithLatitude:[[[notification object] objectForKey:@"GeoAlat"] doubleValue] longitude:[[[notification object] objectForKey:@"GeoA"] doubleValue]];
        
        float radiusInMeters=10000;
        
        NSPredicate *predicate=[NSPredicate predicateWithFormat:@"distanceToLocation:fromLocation:(HomeLocation,%@) < %f  AND %@ < TheDateLastAccessed",home,radiusInMeters,thirtyDaysAgo];
        CKQuery *query=[[CKQuery alloc] initWithRecordType:@"Rides" predicate:predicate];
        query.sortDescriptors =[NSArray arrayWithObject:[[CKLocationSortDescriptor alloc] initWithKey:@"HomeLocation" relativeLocation:home]];
        
        [publicDatabase performQuery:query inZoneWithID:nil completionHandler:
         ^(NSArray *results, NSError *error){
             if(error){
                 if(error.code==CKErrorPartialFailure)error=nil;
             }
             if(error){
                 int seconds=0;
                 if(error.code==CKErrorServiceUnavailable || error.code==CKErrorRequestRateLimited)
                     seconds=[[[error userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                 if(seconds>0){
                     [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to access other users' Rides.  Please try again after %i seconds.",seconds]];
                 }else{
                     [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an error trying to get other users' Rides.  Please try again later. (%@)",error]];
                 }
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnWithMatches" object:@"Error"];
                 });
             }else{
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnWithMatches" object:results];
                 });
             }
         }];
    }
}

-(void)messagesProcedures:(NSNotification *)notification{
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    CKContainer *defaultContainer=[CKContainer defaultContainer];
    CKDatabase *privateDatabase=[defaultContainer privateCloudDatabase];
    CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
   // NSLog(@"the notification object is %@",[notification object]);
    if ([[notification object] isEqual:@"GetMessages"]) {
        [defaultContainer accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
            if (accountStatus == CKAccountStatusNoAccount || ![[parameters objectForKey:@"iCloudAvailable"] boolValue]){
                [self iCloudErrorMessage:[NSString stringWithFormat:@"iCloud is not available.  You cannot receive any messages unless iCloud is available."]];
            }else{
                NSPredicate *predicate=[NSPredicate predicateWithFormat:@"ToNumber == %i",[[parameters objectForKey:@"iCloudRecordID"] intValue] ];
                
                CKQuery *query=[[CKQuery alloc] initWithRecordType:@"Messages" predicate:predicate];
                query.sortDescriptors =[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"DateD" ascending:YES]];
                [publicDatabase performQuery:query inZoneWithID:nil completionHandler:
                 ^(NSArray *results, NSError *error){
                     if(error){
                         if(error.code==CKErrorPartialFailure)error=nil;
                     }
                     if(error){
                         int seconds=0;
                         if(error.code==CKErrorServiceUnavailable || error.code==CKErrorRequestRateLimited)
                             seconds=[[[error userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                         if(seconds>0){
                             [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to get your messages.  Please try again after %i seconds.",seconds]];
                         }else{
                             [self iCloudErrorMessage:@"There was an error trying to get your messages.  Please try again later."];
                         }
                     }else if([results count]>0){
                       //  NSLog(@"and now here %@",results);
                         [self addToPrivateDataBaseTheseRecords:results andDeleteThemFromPublicDatabase:YES];
                     }else{
                         getFromItems=YES;
                         [self downloadMessagesFromPrivateDB];
                     }
                 }];
            }
        }];
    
        
        
    }else if([[notification object] isKindOfClass:[NSString class]]){  // it is message.text or subscriptionswitch
        
        if([[notification object] isEqualToString:@"SubscriptionSwitch"]
         //  || [[notification object] isEqualToString:@"SubscriptionSwitchNil"]
           ){
        //    __block BOOL subscriptionSwitchNil=[[notification object] isEqualToString:@"SubscriptionSwitchNil"];
            [defaultContainer accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
                if (accountStatus == CKAccountStatusNoAccount || ![[parameters objectForKey:@"iCloudAvailable"] boolValue]){
             //       if(subscriptionSwitchNil){
             //           [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             //       }else{
                        [self iCloudErrorMessage:@"iCloud is not available.  You can't change Message Alerts unless iCloud is available."];
                        [parameters setObject:[NSNumber numberWithBool:![[parameters objectForKey:@"SubscriptionSwitch"] boolValue]] forKey:@"SubscriptionSwitch"];
               //     }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnFromCloud" object:@"SubscriptionSwitch"];
                    });
                }else{
                    [publicDatabase fetchAllSubscriptionsWithCompletionHandler:^(NSArray *subscriptions, NSError *error) {
                        if (error) {
                            // if this is from a load or user just ReadAndAgreed then don't issue error message (sender=nil)
                            
                 //           if(subscriptionSwitchNil){
                   //             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                     //       }else{
                                [self iCloudErrorMessage:@"Unable to change Message Alerts.  Please try again later."];
                                [parameters setObject:[NSNumber numberWithBool:![[parameters objectForKey:@"SubscriptionSwitch"] boolValue]] forKey:@"SubscriptionSwitch"];
                     //       }
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnFromCloud" object:@"SubscriptionSwitch"];
                            });
                        } else {
                            NSMutableArray *currentSubscriptionIDs=[[NSMutableArray alloc] initWithCapacity:[subscriptions count]];
                            //    NSLog(@"THE SUBSCRIPTION COUNT IS %lu",(unsigned long)[subscriptions count]);
                            NSString *subscriptionIDToAdd=[NSString stringWithFormat:@"%i",[[parameters objectForKey:@"iCloudRecordID"] intValue]] ;
                            for (CKSubscription *subscription in subscriptions) {
                                [currentSubscriptionIDs addObject:subscription.subscriptionID];
                            }
                            
                        //    NSLog(@"the arrays are %@    and %@",currentSubscriptionIDs,subscriptionIDToAdd);
          
          //                  if(subscriptionSwitchNil)
                                //called from get parameters.
                                //  register notifications on this device 'at launch'.
                                //   other devices owned by this user may have turned on subscription
            //                    [parameters setObject:[NSNumber numberWithBool:[currentSubscriptionIDs containsObject:subscriptionIDToAdd]] forKey:@"SubscriptionSwitch"];
                            
                            
                            // register for notifications and issue an alert if necessary
                            if([[parameters objectForKey:@"SubscriptionSwitch"] boolValue]){
                                UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeBadge | UIUserNotificationTypeAlert;
                                UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
                                [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
                                [[UIApplication sharedApplication] registerForRemoteNotifications];
                            }
                            
                            NSArray *subscriptionToAdd;// add a subscription if switch on and not there
                            if([[parameters objectForKey:@"SubscriptionSwitch"] boolValue] &&
                               ![currentSubscriptionIDs containsObject:subscriptionIDToAdd]){
                                CKNotificationInfo *notification = [CKNotificationInfo new];//[[CKNotificationInfo alloc] init];
                                //  CKNotificationInfo *notificationInfo = [CKNotificationInfo new];
                                notification.alertLocalizationKey = @"Message from %1$@ to %2$@";
                                notification.alertLocalizationArgs=[NSArray arrayWithObjects:@"From",@"ToNumber",nil];
                                notification.shouldBadge=YES;
                                notification.soundName = UILocalNotificationDefaultSoundName;
                                NSPredicate *predicate=[NSPredicate predicateWithFormat:@"ToNumber == %i",[[parameters objectForKey:@"iCloudRecordID"] intValue] ];
                                CKSubscription *itemSubscription = [[CKSubscription alloc] initWithRecordType:@"Messages" predicate:predicate subscriptionID:subscriptionIDToAdd options:CKSubscriptionOptionsFiresOnRecordCreation];
                                //      notification.desiredKeys=[NSArray arrayWithObjects:@"Messages",@"LatestMessage", nil];
                                itemSubscription.notificationInfo = notification;
                                subscriptionToAdd=[NSArray arrayWithObject:itemSubscription];
                            }else{
                                subscriptionToAdd=nil;
                            }
                            
                            if([[parameters objectForKey:@"SubscriptionSwitch"] boolValue] && [currentSubscriptionIDs containsObject:subscriptionIDToAdd] ){
                                [currentSubscriptionIDs removeObject:subscriptionIDToAdd];
                            }
                            // NOTE - at this point "currentSubscriptionIDs" are the ones we want to remove
                            
                            if([currentSubscriptionIDs count]+[subscriptionToAdd count]>0){
                                //   need to do something, delete perhaps, add perhaps
                                
                                CKModifySubscriptionsOperation *modifySubscriptions=[[CKModifySubscriptionsOperation alloc] initWithSubscriptionsToSave:subscriptionToAdd subscriptionIDsToDelete:currentSubscriptionIDs]; // want to delete previous users of this device
                                //       NSLog(@"the arguments are %@   %@",subscriptionToAdd,subscriptionToDelete);
                                modifySubscriptions.qualityOfService=NSQualityOfServiceUserInitiated;
                                modifySubscriptions.modifySubscriptionsCompletionBlock=^(NSArray * savedSubscriptions, NSArray * deletedSubscriptionIDs, NSError * operationError){
                                    
                                    if(operationError){
                                        if(operationError.code==CKErrorPartialFailure){
                                            //  NSLog(@"a partial error saving subscriptions?????    %@",operationError);
                                            operationError=nil;
                                        }
                                    }
                                    if(operationError){
                                        int seconds=0;
                                        if(operationError.code==CKErrorServiceUnavailable || operationError.code==CKErrorRequestRateLimited)
                                            seconds=[[[operationError userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                                        if(seconds>0){
                                            [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to change your Message Alerts.  Please try again after %i seconds.",seconds]];
                                        }else{
                                            //   NSLog(@"the error was  %@",operationError);
                                            [self iCloudErrorMessage:@"There was an error trying to change your Message Alerts.  Please try again later."];
                                        }
                                        
                                        if([subscriptionToAdd count]>1 && [savedSubscriptions count]==0)
                                            [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"SubscriptionSwitch"]; // failed to add
                                        if([currentSubscriptionIDs containsObject:subscriptionIDToAdd] && ![deletedSubscriptionIDs containsObject:subscriptionIDToAdd])
                                            [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"SubscriptionSwitch"];  // failed to delete
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnFromCloud" object:@"SubscriptionSwitch"];
                                        });
                                    }else{
                                      //  NSLog(@"Subscribed succesfully - saved this subscription:  %@   and deleted this subscription:   %@",savedSubscriptions,deletedSubscriptionIDs);
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnFromCloud" object:@"SubscriptionSwitch"];
                                        });
                                    }
                                    
                                    
                     //               [self pushSubscriptionSwitchToMyInfo];  // is this necessary?????
                                    
                                };
                                //     NSLog(@"and here is the subscription just before delete/add operation %@ -  %@",subscriptionNames,itemSubscription);
                                [publicDatabase addOperation:modifySubscriptions];
                            }else{
                                
                        //        [self pushSubscriptionSwitchToMyInfo];  // is this necessary?
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnFromCloud" object:@"SubscriptionSwitch"];
                                });
                                
                            }
                        }
                    }];
                }
            }];
            
        }else{  //   message.text to send
            [defaultContainer accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
                if (accountStatus == CKAccountStatusNoAccount || ![[parameters objectForKey:@"iCloudAvailable"] boolValue]) {
                    [self iCloudErrorMessage:@"iCloud is not available.  You cannot send any messages unless iCloud is available."];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnFromCloud" object:@"ResignNoHide"];
                        
                    });
                }else if ([parameters objectForKey:@"MessageIssue"]){
                    [self iCloudErrorMessage:@"There is an issue with your use of the Message system.  Please you the \"Contact Us\" button on the \"Intro\"page to email us about this issue."];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnFromCloud" object:@"ResignNoHide"];
                        
                    });
                }else{
                    NSString *theMessage=[notification object];
                    NSNumber *fromNumber=[parameters objectForKey:@"iCloudRecordID"];
                    NSNumber *toNumber=[NSNumber numberWithInt:[[theMessage substringFromIndex:[theMessage rangeOfString:@":"].location+1] intValue]];
                    NSString *stringFromFrom=[theMessage substringFromIndex:[theMessage rangeOfString:@"From:"].location];
                    NSString *theCKRecordIdName=[NSString stringWithFormat:@"%@ to %@ on %@",fromNumber,toNumber,[fullDateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]]];
                    CKRecordID *theCKRecordId=[[CKRecordID alloc] initWithRecordName:theCKRecordIdName];
                    CKRecord *aMessage=[[CKRecord alloc] initWithRecordType:@"Messages" recordID:theCKRecordId];
                    [aMessage setObject:fromNumber  forKey:@"From"];
                    [aMessage setObject:toNumber forKey:@"ToNumber"];
                    //   NSLog(@"here ffff");
                    [aMessage setObject:[[theMessage substringFromIndex:[theMessage rangeOfString:@"-"].location+1] substringToIndex:1] forKey:@"ToRide"];
                    
                    [aMessage setObject:[[stringFromFrom substringFromIndex:
                                          [stringFromFrom rangeOfString:@"-"].location+1] substringToIndex:1]forKey:@"FromRide"];
                    NSNumber *theDateD=[NSNumber numberWithDouble: [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSinceReferenceDate]];
                    [aMessage setObject:theDateD  forKey:@"DateD"];
                    
                    [self addToArchiveThisMessage:theMessage];
                    
                  //  NSLog(@"going back 1111   %@",[parameters objectForKey:@"Match ID"]);
                    NSString *theMessageText=[theMessage substringFromIndex:[theMessage rangeOfString:@"  \n"].location+3];
                    [aMessage setObject:theMessageText forKey:@"Message"];
                    
                    NSString *titleString=[NSString stringWithString:theMessageText];
                    
                    if (titleString.length==0)titleString=@"<  >";
                    titleString=[titleString stringByReplacingOccurrencesOfString:@"\n" withString:@"<cr>"];
                    if(titleString.length>=80){
                        if([[titleString substringToIndex:8] isEqualToString:@"We Match"])titleString=[NSString stringWithFormat:@"We Match..%@",[titleString substringFromIndex:79]];
                    }
                    
                    long theLength=titleString.length;
                    if(theLength>32)theLength=32;
                    [aMessage setObject:[titleString substringToIndex:theLength] forKey:@"Title"];
                    
                    
                    
                    //        NSLog(@"here ffff2");
                    [publicDatabase saveRecord:aMessage completionHandler: ^(CKRecord *record, NSError *error){
                        if(error){
                            if(error.code==CKErrorPartialFailure)error=nil;
                        }
                        if(error){
                            int seconds=0;
                            if(error.code==CKErrorServiceUnavailable || error.code==CKErrorRequestRateLimited)
                                seconds=[[[error userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                            NSString *errorMessage;
                            if(seconds>0){
                                errorMessage=[NSString stringWithFormat:@"There was an iCloud resource issue trying to send your message.  Please try again after %i seconds.",seconds];
                            }else{
                                errorMessage=[NSString stringWithFormat: @"There was an error trying to send your message.  Please try again later. %@   %ld",error,(long)error.code];
                            }
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnFromCloud" object:@"ResignNoHide"];
                            });
                            
                            [self iCloudErrorMessage:errorMessage];
                            
                        }else{
                            //  change "Send to 123456-C..." to "To 123456-C
                            
                            //    just saved to public.  now save it locally and in private dbase.
                            //     then retrun with this and any other messages
                            
                            [self addToPrivateDataBaseTheseRecords:[NSArray arrayWithObject:record] andDeleteThemFromPublicDatabase:NO];
                            
                            
                            
                            
                            
                            
                            // at this point add the (int)dated to either 'we match' or to 'messages' in a different record
                            
                            
                            
                            
                            
                        }
                    }];
                    
                    
                }
            }];
            
        }
    }else if([[notification object] isKindOfClass:[NSMutableArray class]]){
        if([[notification object] count]>0){
            /*
            if([[[notification object] objectAtIndex:0] isKindOfClass:[NSNumber class]]){
                // an array of nsnumber dateD objects to remove from the Unread List in MyInfo
                [self resetTheBadge];
                CKRecordID *myInfo = [[CKRecordID alloc] initWithRecordName:@"MyInfo"];
                [privateDatabase fetchRecordWithID:myInfo completionHandler:^(CKRecord *myInfoRecord, NSError *error) {
                    
                    if(error){ // a bad error
                        [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an iCloud error trying to mark some Messages as 'read'.\n\n (%@)",error]];
                    }else{
                        NSMutableArray *theUnreadList=[[NSMutableArray alloc] initWithArray:[myInfoRecord objectForKey:@"UnreadDateDList"] ];
                        for(int I=0;I<[[notification object] count];I++){
                            [theUnreadList removeObject:[[notification object] objectAtIndex:I]];
                        }
                        [myInfoRecord setObject:theUnreadList forKey:@"UnreadDateDList"];
                        CKModifyRecordsOperation *modifyRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:[NSArray arrayWithObject:myInfoRecord] recordIDsToDelete:nil];
                        modifyRecords.modifyRecordsCompletionBlock=^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
                            if(operationError){
                                if(operationError.code==CKErrorPartialFailure){
                                    NSLog(@"a partial error saving sunread list ?????    %@",operationError);
                                    operationError=nil;
                                }
                            }
                            if(operationError){
                                int seconds=0;
                                if(operationError.code==CKErrorServiceUnavailable || operationError.code==CKErrorRequestRateLimited)
                                    seconds=[[[operationError userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                                if(seconds>0){
                                    [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to mark some Messages as 'Read'.  Please try again after %i seconds.",seconds]];
                                }else{
                                    //   NSLog(@"the error was  %@",operationError);
                                    [self iCloudErrorMessage:@"There was an error trying to mark some Messages as 'Read'.  Please try again later."];
                                }
                            }else{
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                });
                            }
                        };
                        [privateDatabase addOperation:modifyRecords];
                    }
                }];
                
            }else  */
            if([[[notification object] objectAtIndex:0] isKindOfClass:[NSDictionary class]]){
                // an array of messages that need to be deleted from private db and zone
             
                [defaultContainer accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
                    if (accountStatus == CKAccountStatusNoAccount || ![[parameters objectForKey:@"iCloudAvailable"] boolValue]) {
                        [self iCloudErrorMessage:@"iCloud is not available.  You cannot delete any message unless iCloud is available."];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnFromCloud" object:@"FailedToDelete"];
                        });
                    }else{
                        
                        CKRecordZoneID *messageZoneID=[[CKRecordZoneID alloc] initWithZoneName:@"MessageZone" ownerName:CKOwnerDefaultName];
                        NSArray *messagesToDelete=[notification object];
                        NSMutableArray *recordIDsToDelete=[[NSMutableArray alloc] initWithCapacity:[messagesToDelete count]];
                        NSMutableDictionary *iDsAndDateD=[[NSMutableDictionary alloc] initWithCapacity:[messagesToDelete count]] ;
                        
                     //   NSMutableArray *removeFromUnreadList=[[NSMutableArray alloc] init];
                        NSMutableArray *removeFromPublicDatabase=[[NSMutableArray alloc] init];
                        NSArray *messagesToDeleteDateD=[messagesToDelete valueForKey:@"DateD"];
                        //     NSMutableArray *theDateDsToDelete=[[NSMutableArray alloc] initWithCapacity:
                        //                                        [messagesToDelete count]];
                        for(int I=0;I<[messagesToDelete count];I++){
                            NSDictionary *aMessageToDelete=[messagesToDelete objectAtIndex:I];
                            NSString *theRecordName=[NSString stringWithFormat:@"%@ to %@ on %@",
                                                     [aMessageToDelete objectForKey:@"From"],
                                                     [aMessageToDelete objectForKey:@"ToNumber"],
                                                     [fullDateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:[[aMessageToDelete objectForKey:@"DateD"] doubleValue]]]];
                            CKRecordID *aCKRecordId=[[CKRecordID alloc] initWithRecordName:theRecordName zoneID:messageZoneID];
                            [recordIDsToDelete addObject:aCKRecordId];
                            [iDsAndDateD setObject:[aMessageToDelete objectForKey:@"DateD"] forKey:aCKRecordId.recordName];
                            
                            if([[aMessageToDelete objectForKey:@"Read"] isEqualToString:@"No"] ||
                               [[aMessageToDelete objectForKey:@"Read"] isEqualToString:@"Just saved"]){
                             //   [removeFromUnreadList addObject:[aMessageToDelete objectForKey:@"DateD"]];
                                [removeFromPublicDatabase addObject:[[CKRecordID alloc] initWithRecordName:theRecordName]];
                            }
                        //    if([[aMessageToDelete objectForKey:@"Read"] isEqualToString:@"Just downloaded"]){
                        //        [removeFromUnreadList addObject:[aMessageToDelete objectForKey:@"DateD"]];
                        //    }
                        }
                        CKModifyRecordsOperation *modifyRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:recordIDsToDelete];
                        modifyRecords.savePolicy=CKRecordSaveAllKeys;
                        modifyRecords.qualityOfService=NSQualityOfServiceUserInitiated;
                        modifyRecords.modifyRecordsCompletionBlock=^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
                            if(operationError){
                                if(operationError.code==CKErrorPartialFailure){
                                  //  NSLog(@"a partial error deleting messages?????    %@",operationError);
                                    operationError=nil;
                                }
                            }
                            if(operationError){
                                int seconds=0;
                                if(operationError.code==CKErrorServiceUnavailable || operationError.code==CKErrorRequestRateLimited)
                                    seconds=[[[operationError userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                                if(seconds>0){
                                    [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to delete messages.  Please try again after %i seconds.",seconds]];
                                }else{
                                    //   NSLog(@"the error was  %@",operationError);
                                    [self iCloudErrorMessage:@"There was an error trying to delete some messages.  Please try again later."];
                                }
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnFromCloud" object:@"FailedToDelete"];
                                });
                            }else{
                                
                                for(long I=[myMessages count]-1;I>=0;I--){
                                    
                                //    NSLog( @"do these match   %@   %@ ",messagesToDeleteDateD,[[myMessages objectAtIndex:I] objectForKey:@"DateD"]);
                                    if([messagesToDeleteDateD containsObject:[[myMessages objectAtIndex:I] objectForKey:@"DateD"]]){
                                        [myMessages removeObjectAtIndex:I];
                                  //      NSLog(@"removing a message");
                                    }
                                }
                                if([myMessages count]==0)[myMessages addObject:@"No messages"];
                                [self resetTheBadge]; // cleares the notifications
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnFromCloud" object:@"DoneWithDelete"];
                                });
                                
                                
                                if([removeFromPublicDatabase count]>0){
                                    CKModifyRecordsOperation *modifyPublicRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:removeFromPublicDatabase];
                                    modifyPublicRecords.savePolicy=CKRecordSaveAllKeys;
                                    modifyPublicRecords.qualityOfService=NSQualityOfServiceUserInitiated;
                                    modifyPublicRecords.modifyRecordsCompletionBlock=^(NSArray * savedXRecords, NSArray * deletedRecordIDs, NSError * operationError){
                                        if(operationError){
                                            if(operationError.code==CKErrorPartialFailure){
                                                //  NSLog(@"a partial error?????    %@",operationError);
                                                operationError=nil;
                                            }
                                        }
                                        
                                        if(operationError){
                                            int seconds=0;
                                            if(operationError.code==CKErrorServiceUnavailable || operationError.code==CKErrorRequestRateLimited)
                                                seconds=[[[operationError userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                                            if(seconds>0){
                                                [self iCloudErrorMessage:@"There was an iCloud resource issue trying to delete sent Messages.  They will still be sent."];
                                            }else{
                                                //   NSLog(@"the error was  %@",operationError);
                                                [self iCloudErrorMessage:@"There was an error trying to delete sent Messages.  They will still be sent."];
                                            }
                                        }else{
                                        //    if([removeFromUnreadList count]>0){
                                          //      [[NSNotificationCenter defaultCenter] postNotificationName:@"MessagesProcedures" object:removeFromUnreadList];  // will terminate therein
                                        //    }else{
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                                });
                                       //     }
                                        }
                                    };
                                    [[defaultContainer publicCloudDatabase] addOperation:modifyPublicRecords];
                         //       }else if([removeFromUnreadList count]>0){  // may also be done inside above
                           //         [[NSNotificationCenter defaultCenter] postNotificationName:@"MessagesProcedures" object:removeFromUnreadList];  // will terminate therein
                                }else{
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                    });
                                }
                            }
                        };
                        [privateDatabase addOperation:modifyRecords];
                    }
                }];
            }
        }
    }
}

/*
-(void)pushSubscriptionSwitchToMyInfo{
    CKContainer *defaultContainer=[CKContainer defaultContainer];
    CKDatabase *privateDatabase=[defaultContainer privateCloudDatabase];
    CKRecordID *myInfo = [[CKRecordID alloc] initWithRecordName:@"MyInfo"];
    CKRecord *myInfoRecord=[[CKRecord alloc] initWithRecordType:@"Info" recordID:myInfo];
    [myInfoRecord setObject:[parameters objectForKey:@"SubscriptionSwitch"] forKey:@"SubscriptionSwitch"];
    CKModifyRecordsOperation *modifyRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:[NSArray arrayWithObject:myInfoRecord] recordIDsToDelete:nil];
    modifyRecords.savePolicy=CKRecordSaveAllKeys;
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
                [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying record changes to your Message Alerts  Please try again after %i seconds.\n\n(%@)",seconds,operationError]];
            }else{
                //     NSLog(@"the error was  %@",operationError);
                [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an iCloud error trying to record changes to your Message Alerts.  Please try again later.\n\n (%@)",operationError]];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnFromCloud" object:@"SubscriptionSwitch"];
        });
    };
    [privateDatabase addOperation:modifyRecords];
}

*/


-(void)resetTheBadge{  // best to do this only after a recent getMessages but not so bad if not
    //   want to set the badge to the number of messages that have not yet been read and are labelled 'just downloaded" - want to do the same to the app icon badge.
    long numberOfMessages=0;
    for(int I=0;I<[myMessages count];I++){
        if([[myMessages objectAtIndex:I] isKindOfClass:[NSDictionary class]]){
            if([[[myMessages objectAtIndex:I] objectForKey:@"Read"] isEqualToString:@"Just downloaded"])
                numberOfMessages++;
        }
    }
    CKModifyBadgeOperation *resetBadge=[[CKModifyBadgeOperation alloc] initWithBadgeValue:numberOfMessages];
    resetBadge.qualityOfService=NSQualityOfServiceUserInitiated;
    [[CKContainer defaultContainer] addOperation:resetBadge];
    
}

-(void)addToArchiveThisMessage:(NSString *)theMessage{
  //  NSLog(@"going back");
    
    CKContainer *defaultContainer=[CKContainer defaultContainer];
    CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
    CKRecordID *archiveRecordID = [[CKRecordID alloc] initWithRecordName:@"MessageArchive"];
    [publicDatabase fetchRecordWithID:archiveRecordID completionHandler:^(CKRecord *archiveRecord, NSError *error) {
        if([error code]==CKErrorUnknownItem){  // no private database yet, create it
            CKRecord *archiveRecord=[[CKRecord alloc] initWithRecordType:@"MessageArchive" recordID:archiveRecordID];
            [archiveRecord setObject:[[NSArray alloc] initWithObjects:theMessage,nil] forKey:@"TheMessages"];
            [publicDatabase saveRecord:archiveRecord completionHandler:^(CKRecord *record, NSError *error){
                if(error){
                  //  NSLog(@"there was an error going back  %@",error);
                }
            }];
        }else if(archiveRecord){
            NSMutableArray *theMessages=[archiveRecord objectForKey:@"TheMessages"];
            NSString *modifiedMessage=[[[[[theMessage stringByReplacingOccurrencesOfString:@"To:  " withString:@"T:"] stringByReplacingOccurrencesOfString:@"  From: " withString:@"F:"] stringByReplacingOccurrencesOfString:@"\n             Date:" withString:@"  "] stringByReplacingOccurrencesOfString:@"\nWe Match.  If you are interested in Ride Sharing please respond to this message." withString:@"We Match... "] stringByAppendingString:@"    "];
            [theMessages addObject:modifiedMessage];
            [archiveRecord setObject:theMessages forKey:@"TheMessages"];
            CKModifyRecordsOperation *modifyRecords=
                [[CKModifyRecordsOperation alloc] initWithRecordsToSave:[NSArray arrayWithObject: archiveRecord]  recordIDsToDelete:nil];
            modifyRecords.savePolicy=CKRecordSaveAllKeys;
            modifyRecords.qualityOfService=NSQualityOfServiceUserInitiated;
            [publicDatabase addOperation:modifyRecords];
        }
    }];
}




-(void)addToPrivateDataBaseTheseRecords:(NSArray *)messageArray andDeleteThemFromPublicDatabase:(BOOL)deleteThem{
    CKContainer *defaultContainer=[CKContainer defaultContainer];
    CKDatabase *privateDatabase=[defaultContainer privateCloudDatabase];
 //   CKRecordID *myInfo = [[CKRecordID alloc] initWithRecordName:@"MyInfo"];
 //   [privateDatabase fetchRecordWithID:myInfo completionHandler:^(CKRecord *myInfoRecord, NSError *error) {
//        if(error){ // a bad error
  //          [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an iCloud error trying to access your database.  Please try again later.\n\n (%@)",error]];
  //      }else{
            NSMutableArray *theRecordsToSave=[[NSMutableArray alloc] initWithCapacity:[messageArray count]+1];
        //    NSMutableArray *theUnreadList=[[NSMutableArray alloc] initWithArray:[myInfoRecord objectForKey:@"UnreadDateDList"] ];
            
            [self addTheseMessages:messageArray toRecordsToSave:theRecordsToSave];
     //       [self addTheseMessages:messageArray toUnreadList:theUnreadList];
          //  NSLog(@"here 111");
    
            
            
    //        [myInfoRecord setObject:theUnreadList forKey:@"UnreadDateDList"];
     //       [theRecordsToSave addObject:myInfoRecord];
        
    //        NSLog( @"these are the records to save   %@",theRecordsToSave);
            
            
            CKModifyRecordsOperation *modifyRecords=
                [[CKModifyRecordsOperation alloc] initWithRecordsToSave:theRecordsToSave recordIDsToDelete:nil];
            modifyRecords.savePolicy=CKRecordSaveAllKeys;
            modifyRecords.qualityOfService=NSQualityOfServiceUserInitiated;
            modifyRecords.modifyRecordsCompletionBlock=^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
                if(operationError){
                    if(operationError.code==CKErrorPartialFailure){
                     //   NSLog(@"a partial error?????  WHAT DO I DO????  %@",operationError);
                        //operationError=nil;
                    }
                }
                if(operationError){
                    int seconds=0;
                    if(operationError.code==CKErrorServiceUnavailable || operationError.code==CKErrorRequestRateLimited)
                        seconds=[[[operationError userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                    if(seconds>0){
                        [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to send or receive your Messages.  Please try again after %i seconds.\n\n(%@)",seconds,operationError]];
                    }else{
                        //     NSLog(@"the error was  %@",operationError);
                        [self iCloudErrorMessage:[NSString stringWithFormat: @"There was an iCloud error trying to send or receive your Messages.  Please try again later.\n\n (%@)",operationError]];
                    }
                }else{
                    
                //    NSLog(@"these are the saved messages    %@",savedRecords);
                    
                    
                    if(!deleteThem){
                        getFromItems=NO;
                        [self downloadMessagesFromPrivateDB];
                    }else{  // delete them from public database
                        NSMutableArray *theRecordIDs=[[NSMutableArray alloc] initWithCapacity:[messageArray count]];
                        for(int I=0;I<[savedRecords count];I++){
                            CKRecordID *aCKRecordId=[[CKRecordID alloc] initWithRecordName: //@"a name here" ];
                                [NSString stringWithFormat:@"%@ to %@ on %@",
                                 [[savedRecords objectAtIndex:I] objectForKey:@"From"],
                                 [[savedRecords objectAtIndex:I] objectForKey:@"ToNumber"],
                                    [fullDateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:[[[savedRecords objectAtIndex:I] objectForKey:@"DateD"] doubleValue]]]] ];
                            [theRecordIDs addObject:aCKRecordId];
                        }
                        CKModifyRecordsOperation *modifyPublicRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:theRecordIDs];
                        modifyPublicRecords.savePolicy=CKRecordSaveAllKeys;
                        modifyPublicRecords.qualityOfService=NSQualityOfServiceUserInitiated;
                        modifyPublicRecords.modifyRecordsCompletionBlock=^(NSArray * savedXRecords, NSArray * deletedRecordIDs, NSError * operationError){
                            if(operationError){
                                if(operationError.code==CKErrorPartialFailure){
                                    //  NSLog(@"a partial error?????    %@",operationError);
                                    operationError=nil;
                                }
                            }
                            if(operationError){
                                int seconds=0;
                                if(operationError.code==CKErrorServiceUnavailable || operationError.code==CKErrorRequestRateLimited)
                                    seconds=[[[operationError userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                                if(seconds>0){
                                    [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to retrieve and then delete your retrieved Messages from the server.  Please try again after %i seconds.",seconds]];
                                }else{
                                    //   NSLog(@"the error was  %@",operationError);
                                    [self iCloudErrorMessage:@"There was an error trying to retrieve and then delete your retrieved Messages from the server.  Please try again later."];
                                }
                            }else{
                              //  NSLog(@"no...here I am");
                                getFromItems=YES;
                                [self downloadMessagesFromPrivateDB];  //happens too quickly
                            }
                        };
                        [[defaultContainer publicCloudDatabase] addOperation:modifyPublicRecords];
                    }
                }
            };
            [privateDatabase addOperation:modifyRecords];
     //   }
 //   }];
}

-(void)downloadMessagesFromPrivateDB{  // do a fetch with token
    NSMutableArray *theMessages=[[NSMutableArray alloc] init];
    NSMutableArray *theIdNamesDeleted=[[NSMutableArray alloc] init];
    CKRecordZoneID *messageZoneID=[[CKRecordZoneID alloc] initWithZoneName:@"MessageZone" ownerName:CKOwnerDefaultName];
    CKFetchRecordChangesOperation *getMessages=[[CKFetchRecordChangesOperation alloc] initWithRecordZoneID:messageZoneID previousServerChangeToken: [parameters objectForKey:@"MessagesToken"]];
    __weak CKFetchRecordChangesOperation *weakGetMessages=getMessages;
  //  NSLog(@"the token is %@",[parameters objectForKey:@"MessagesToken"]);
    
    getMessages.qualityOfService=NSQualityOfServiceUserInitiated;
    getMessages.recordChangedBlock=^(CKRecord *aMessage){
        // construct the local message here from the private record....
        [theMessages addObject:aMessage];
    };
    getMessages.recordWithIDWasDeletedBlock=^(CKRecordID *aRecordId){
        [theIdNamesDeleted addObject:aRecordId.recordName];
    };
    
    getMessages.fetchRecordChangesCompletionBlock=^(CKServerChangeToken *serverChangeToken, NSData *clientChangeTokenData, NSError *operationError){
      
        
        
        if(operationError){
            [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud error downloading your Messages from your iCloud database.  (%@)",operationError]];
        }else{
            
            //server token
            if(serverChangeToken){
                [parameters setObject:serverChangeToken forKey:@"MessagesToken"];
            }else{
                [parameters removeObjectForKey:@"MessageToken"];
            }
            
            //clear all notifications - asynchronously
            NSMutableArray *notificationsForAnyone = [NSMutableArray array];
            CKFetchNotificationChangesOperation *operation = [[CKFetchNotificationChangesOperation alloc] initWithPreviousServerChangeToken:nil];
            operation.qualityOfService=NSQualityOfServiceUserInitiated;
            operation.notificationChangedBlock = ^(CKNotification *notification) {
                if(notification.notificationType==1){
                    if([notification.alertLocalizationArgs count]>0)
                        [notificationsForAnyone addObject:notification.notificationID];
                }
            };
            operation.completionBlock = ^(){
                if([notificationsForAnyone count]>0){
                    CKMarkNotificationsReadOperation *op = [[CKMarkNotificationsReadOperation alloc] initWithNotificationIDsToMarkRead:notificationsForAnyone];
                    op.qualityOfService=NSQualityOfServiceUserInitiated;
                    [[CKContainer defaultContainer] addOperation:op];
                }
            };
            [[CKContainer defaultContainer] addOperation:operation];
            
            //handle the deleted messages:
            if(![[myMessages objectAtIndex:0] isEqual:@"No messages"] && [theIdNamesDeleted count]>0){
                for(long I=[myMessages count]-1;I>=0;I--){
                    if([theIdNamesDeleted containsObject:[[myMessages objectAtIndex:I] objectForKey:@"RecordIdName" ]])[myMessages removeObjectAtIndex:I];
                }
            }
            if([myMessages count]==0)[myMessages addObject:@"No messages"];
            
            //handle new messages gotten as theMessages above
            NSArray *theCurrentDateDs;
            if([[myMessages objectAtIndex:0] isEqual:@"No messages"]){
                theCurrentDateDs=[[NSArray alloc] init];
            }else{
                theCurrentDateDs=[myMessages valueForKey:@"DateD"];
            }
        //    NSLog(@"here 222  %@",theMessages);
            NSMutableArray *newMessagesAsDictionaries=[[NSMutableArray alloc] initWithCapacity:[theMessages count]];
            for (int I=0;I<[theMessages count]; I++){
                CKRecord *aMessage=[theMessages objectAtIndex:I];
                
                if(![theCurrentDateDs containsObject:[aMessage objectForKey:@"DateD"]]){
                    
              //      if([aMessage objectForKey:@"ToNumber"]){  // it might be the MyInfo record
                        NSMutableString *readString=  [[NSMutableString alloc] initWithString: @"Just saved"];
                        if([[aMessage objectForKey:@"ToNumber"] isEqualToNumber:[parameters objectForKey:@"iCloudRecordID"]]){
                            [readString setString: @"Just downloaded"];
                        }
                        NSDictionary *aMessageToDownload=[NSDictionary dictionaryWithObjectsAndKeys:[aMessage objectForKey:@"ToNumber"] ,@"ToNumber",[aMessage objectForKey:@"ToRide"] ,@"ToRide",[aMessage objectForKey:@"FromRide"] ,@"FromRide",[aMessage objectForKey:@"From"] ,@"From",[aMessage objectForKey:@"Message"] ,@"Message",[aMessage objectForKey:@"DateD"] ,@"DateD",readString,@"Read",aMessage.recordID.recordName, @"RecordIdName", nil];
                        [newMessagesAsDictionaries addObject:aMessageToDownload];
                        //  NSLog(@"the messages here are ..........%@",aMessageToDownload);
              //      }
                }
            }
            
            NSSortDescriptor *byDateD=[[NSSortDescriptor alloc] initWithKey:@"DateD" ascending:YES];
            NSArray *sortedMessages=[newMessagesAsDictionaries sortedArrayUsingDescriptors:[NSArray arrayWithObject:byDateD]];
            [myMessages addObjectsFromArray:sortedMessages];
            [self resetTheBadge];
            
            
            if(weakGetMessages.moreComing){
              //  NSLog(@"GETTING MORE!!!!!!!!");
                [self downloadMessagesFromPrivateDB];
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] cancelAllLocalNotifications];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReturnFromCloud" object:@"GotMessages"];
                    if(getFromItems ){
                        [self getMyFromUnreadItems]; // these results will affect blue/grey icon in messages
                    }else{
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    }
                });
            }
        }
    };
    [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:getMessages];
}

-(void)setCurrentVersionNumber{
   // NSLog(@"RESETTING in cloudkitdatabase");
    [parameters setObject:@"1.3" forKey:@"VersionNumber"];
}




-(void)iCloudErrorMessage:(NSString *)message{
    dispatch_async(dispatch_get_main_queue(), ^{
        if([[UIApplication sharedApplication]keyWindow].rootViewController.presentedViewController){
            [self performSelector:@selector(iCloudErrorMessage:) withObject:message afterDelay:0.4f];
        }else{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"iCloud Error" message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Sorry" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [[[UIApplication sharedApplication]keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}




@end
