//
//  ThirdViewController.m
//  PrincetonRideShare
//
//  Created by Peter B Kramer on 6/7/15.
//  Copyright (c) 2015 Peter B Kramer. All rights reserved.
//

#import "ThirdViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "ChoicesViewController.h"


@interface ThirdViewController (){
    NSMutableArray *theRides;
    NSMutableDictionary *theSelectedRide;
    MKPointAnnotation *myHome;
    MKPointAnnotation *myWork;
    NSMutableArray *myAnnotations;
    BOOL requestFromAlert;
    NSDateFormatter *dateFormat;
    NSString* iDNumberSelected;
//    NSString *rideLetter;
    float edgeDistance;
//    NSString *theAnnotationTitleString;
    NSArray *theAnnotationTitleArray;
    MKAnnotationView *theHomeAnnotationView;
    MKAnnotationView *theWorkAnnotationView;
    NSString *theSelectedAnnotation;
//    NSString *showHomeValue;
    NSMutableDictionary *parameters;
    int randomNumber;
}

@end



@implementation ThirdViewController

-(void)getParameters:(NSMutableDictionary *)theParameters{
    parameters=theParameters;
 //   NSLog(@"got parameters in second    %@",parameters);
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    theRides=[parameters objectForKey:@"TheRides"];
    rideSelector.selectedSegmentIndex=[[parameters objectForKey:@"RideSelected"] longValue];
    
    [self changeSelectedRide:nil];  // resets map if needed then redraws the screen
   
    
    if(![parameters objectForKey:@"TimeOfLastUpdate"]){
        [parameters setObject:[NSDate dateWithTimeIntervalSinceNow:-24*60*60] forKey:@"TimeOfLastUpdate"];
    }
    if(![parameters objectForKey:@"UpdateInformation"]){
        [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"UpdateInformation"];
    }
    if([[parameters objectForKey:@"UpdateInformation"] boolValue] || [[parameters objectForKey:@"TimeOfLastUpdate"] timeIntervalSinceNow]<=-24*60*60){
        
                [self pushMyDataToCloud];
          
    }
    
    
    
    
}

-(void)showChoicesWith:(int)selection{
    ChoicesViewController *choices = [[ChoicesViewController alloc] initWithNibName:@"ChoicesViewController" bundle:nil];
    [choices selectionIs:selection];
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:choices];
    navigationController.modalPresentationStyle=UIModalPresentationFormSheet;
    navigationController.navigationBar.tintColor=[UIColor colorWithRed:.9 green:.0 blue:0 alpha:1.0];
    
    [self presentViewController:navigationController animated:YES completion:nil];
    
}


-(void)iCloudErrorMessage:(NSString *)message{
    
    dispatch_async(dispatch_get_main_queue(), ^{
    //    NSLog(@"Issue an error message");
        if(self.presentedViewController){
          //  NSLog(@"Issue a delay");
            [self performSelector:@selector(iCloudErrorMessage:) withObject:message afterDelay:0.4f];
        }else{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [self titleForMatchNearA:@"Match times       ."];
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"iCloud Error" message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Sorry" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    });
}


-(void)downloadMatchData{
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    CKContainer *defaultContainer=[CKContainer defaultContainer];
    CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
    
    NSMutableArray *recordIDs=[[NSMutableArray alloc] initWithCapacity:5];
    for (int I=0;I<=5;I++){
        [recordIDs addObject:[[CKRecordID alloc] initWithRecordName:[NSString stringWithFormat:@"%i%i",[[parameters objectForKey:@"Show Match"] intValue],I]]];
    }
    NSString *theRideLetter=[[parameters objectForKey:@"Show Match"] substringFromIndex:7];
    int rideSelected=(int)[@"0ABCDE!!!!!!!" rangeOfString:theRideLetter ].location;
    [parameters removeObjectForKey:@"Show Match"];
 //   NSLog(@"the ride letter is %@   %i",theRideLetter,rideSelected);
    CKFetchRecordsOperation *fetchRecords=[[CKFetchRecordsOperation alloc] initWithRecordIDs:recordIDs];
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
                [self iCloudErrorMessage:@"There was an error (1) trying to get the Match data.  Please try again later."];
            }
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                NSMutableArray *theResults=[[NSMutableArray alloc] initWithArray:[recordsByRecordID allValues]];
                for(long I=[theResults count]-1;I>=0; I--){
                    if([[[theResults objectAtIndex:I] objectForKey:@"IDNumber"] intValue]%10 ==0)[theResults removeObjectAtIndex:I];
                }
                
                CLLocation *home1=[[CLLocation alloc] initWithLatitude:[[theSelectedRide objectForKey:@"GeoAlat"] doubleValue] longitude:[[theSelectedRide objectForKey:@"GeoA"] doubleValue]];
                
                NSArray *theResultsSorted=[theResults sortedArrayUsingComparator:^(id obj1, id obj2){
                    NSDictionary *object1=obj1;
                    NSDictionary *object2=obj2;
                    if([[object1 objectForKey:@"IDNumber"] intValue]%10==rideSelected){
                        return (NSComparisonResult)NSOrderedAscending;
                    }else if([[object1 objectForKey:@"HomeLocation"] distanceFromLocation:home1]>
                       [[object2 objectForKey:@"HomeLocation"] distanceFromLocation:home1] ){
                        return (NSComparisonResult)NSOrderedDescending;
                    }else{
                        return NSOrderedAscending;
                    }
                }];
                
                
                [theSelectedRide setObject:theResultsSorted forKey:@"Nearby50"];
                
                [self titleForMatchNearA:@"Match times       ."];  // this is a method
                
                
                
                    NSArray *currentAnnotations=[mapIt annotations];
                     NSString *whatToShow=@"Home 1";
                    NSString *whatToShowComma=@"Home 1,";
                    for (int I=0;I<[currentAnnotations count] ; I++) {
                        NSString *currentTitle=[[currentAnnotations objectAtIndex:I] title];
                    //    NSLog(@"the currentTitle is %@",currentTitle);
                        if(currentTitle.length<6 || currentTitle.length<whatToShow.length)currentTitle=@"this is a longer title"; //  in both cases it doesn't contain whatToShow so just preven crashes
                        if([currentTitle containsString:whatToShowComma] ||
                           [[currentTitle substringFromIndex:(currentTitle.length-whatToShow.length)] isEqualToString:whatToShow]){
                            requestFromAlert=YES;
                            [mapIt selectAnnotation:[currentAnnotations objectAtIndex:I] animated:YES];
                            MKPointAnnotation *theAnnotation=[currentAnnotations objectAtIndex:I];
                            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(theAnnotation.coordinate,mapIt.region.span.latitudeDelta*1000/.009006, mapIt.region.span.longitudeDelta*1000/.014);
                            
                            [mapIt setRegion:region animated:YES];
                            
                            [self performSelector:@selector(deselectAnnotation:) withObject:[currentAnnotations objectAtIndex:I] afterDelay:3.0f];
                            break;
                            
                        }
                    }
                
            });
        }

        
        
    
    };
    [publicDatabase addOperation:fetchRecords];
    
    
}
-(void)downloadData{
    
    
    //  here you go out to CloudKit and download 50 users closest to the home location.
    
    
    // test if icloud is available
        //   no  - issue alert and stop
        //   yes
                //  construct query for time within last 30 days and location closest 50
                       //  when you get these results go off to packagedataandproceed
                // also check if there is a current icloud account
                        //   if no icloud access issue an alert (if within one day) and stop
                        //   if icloud access and no account then create an account and then post to it
                        //   if icloud access and account post to it
    
    
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    CKContainer *defaultContainer=[CKContainer defaultContainer];
    CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
    
    NSDate *thirtyDaysAgo=[NSDate dateWithTimeIntervalSinceNow:-30*24*3600] ;
//    float radiusInKilometers=5;
    CLLocation *home=[[CLLocation alloc] initWithLatitude:[[theSelectedRide objectForKey:@"GeoAlat"] doubleValue] longitude:[[theSelectedRide objectForKey:@"GeoA"] doubleValue]];
    
    float radiusInMeters=10000;

   NSPredicate *predicate=[NSPredicate predicateWithFormat:@"distanceToLocation:fromLocation:(HomeLocation,%@) < %f  AND %@ < TheDateLastAccessed",home,radiusInMeters,thirtyDaysAgo];
    

    // theDateLastAccessed is an NSDate object
    //  homeLocation is a CLLocation object
    
 //   NSPredicate *predicate=[NSPredicate predicateWithFormat:@"%@ < TheDateLastAccessed",thirtyDaysAgo];
    CKQuery *query=[[CKQuery alloc] initWithRecordType:@"Rides" predicate:predicate];
    query.sortDescriptors =[NSArray arrayWithObject:[[CKLocationSortDescriptor alloc] initWithKey:@"HomeLocation" relativeLocation:home]];
    
    [publicDatabase performQuery:query inZoneWithID:nil completionHandler:
     ^(NSArray *results, NSError *error){
         if(error){
             if(error.code==CKErrorPartialFailure)error=nil;
          //   if(error.code==CKErrorServerRejectedRequest)error=nil;
             
             //    NSLog(@"the error code is -%ld-",(long)error.code);
         }
         if(error){
             int seconds=0;
             if(error.code==CKErrorServiceUnavailable || error.code==CKErrorRequestRateLimited)
                 seconds=[[[error userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
             if(seconds>0){
                 [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to access other users' Rides.  Please try again after %i seconds.",seconds]];
             }else{
              //   NSLog(@"error is %ld   %@",(long)error.code,error);
                 
                 [self iCloudErrorMessage:@"There was an error trying to get other users' Rides.  Please try again later."];
             }
             // return ;
         }else{
    
             // here are the results in sorted order...I think
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                 NSMutableArray *theResults=[[NSMutableArray alloc] initWithArray:results];
                 
                 CLLocation *home1=[[CLLocation alloc] initWithLatitude:[[theSelectedRide objectForKey:@"GeoAlat"] doubleValue] longitude:[[theSelectedRide objectForKey:@"GeoA"] doubleValue]];
                 
                 for(long I=[theResults count]-1;I>=0; I--){
                     
                     
                     if([[[theResults objectAtIndex:I] objectForKey:@"IDNumber"] intValue]/10 ==[[parameters objectForKey:@"iCloudRecordID"] intValue]  ||
                        [[[theResults objectAtIndex:I] objectForKey:@"IDNumber"] intValue]%10 ==0)[theResults removeObjectAtIndex:I];
                 }
                 
                 NSArray *theResultsLessMe=[theResults sortedArrayUsingComparator:^(id obj1, id obj2){
                     NSDictionary *object1=obj1;
                     NSDictionary *object2=obj2;
                     if([[object1 objectForKey:@"HomeLocation"] distanceFromLocation:home1]>
                        [[object2 objectForKey:@"HomeLocation"] distanceFromLocation:home1]){
                            return (NSComparisonResult)NSOrderedDescending;
                     }else{
                         return NSOrderedAscending;
                     }
                 }];
                 
                 
                 [theSelectedRide setObject:theResultsLessMe forKey:@"Nearby50"];
                 [theSelectedRide setObject:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"TimeLastDownloaded"];
                 [self titleForMatchNearA:@"Match times       ."];  // this is a method
                 
           //      NSLog(@"going to dataWasDownloaded");
           //      [self dataWasDownloaded];
                // return ;
             });
         }
     }];
  
    
    
}

-(void)titleForMatchNearA:(NSString *)title{
 //   NSLog(@"here 222222    %@",title);
    [matchNearA setTitle:title forState:UIControlStateDisabled];
    if([title isEqualToString:@"Match times       ."]){
        [matchNearA setTitleColor:[UIColor colorWithRed:0 green:122/255. blue:1.0 alpha:1.0] forState:UIControlStateDisabled];
        
        [matching stopAnimating];
        [getDataOrStop setImage:[UIImage imageNamed:@"Circle image 21.png"] forState:UIControlStateNormal];
        getDataOrStop.hidden=NO;
        matchNearA.enabled=NO;
        filterData.hidden=NO;
        [self matchRides:nil]; //  does a full display of filtered or not filtered
    }else if([title isEqualToString:@"Set Home!"]){
        [matchNearA setTitleColor:[UIColor colorWithRed:1.0 green:0 blue:.0 alpha:1.0] forState:UIControlStateNormal];
        [matching stopAnimating];
        [getDataOrStop setImage:[UIImage imageNamed:@"Circle image 21.png"] forState:UIControlStateNormal]; // doesn't matter but reset it anyway
        [matchNearA setTitle:title forState:UIControlStateNormal];  // it's enabled not disabled
        getDataOrStop.hidden=YES;
        matchNearA.enabled=YES;
        filterData.hidden=YES;
    }else if([title isEqualToString:@"Downloading..."]){
        [matchNearA setTitleColor:[UIColor colorWithRed:85./255. green:85./255. blue:85./255. alpha:1.0] forState:UIControlStateDisabled];
        [matching startAnimating];
        [getDataOrStop setImage:[UIImage imageNamed:@"X image 21.png"] forState:UIControlStateNormal];
        getDataOrStop.hidden=NO;
        matchNearA.enabled=NO;
        filterData.hidden=YES;
    }
 //   NSLog(@"here 222224");
    
}



-(void)pushMyDataToCloud{
    
    
    
    [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
        if (accountStatus == CKAccountStatusNoAccount) {
            if(![parameters objectForKey:@"TimeOfLastAlert"]){
                [parameters setObject:[NSDate dateWithTimeIntervalSinceNow:-600] forKey:@"TimeOfLastAlert"];
            }
            
            //  you might be using this to find people near you even when you are not logged in...don't repeated show error.
            
      //      NSLog(@"here f  %f",[[parameters objectForKey:@"TimeOfLastAlert"] timeIntervalSinceNow]);
            dispatch_async(dispatch_get_main_queue(), ^{
                if([[parameters objectForKey:@"TimeOfLastAlert"] timeIntervalSinceNow]<=-30 &&
                   !self.presentedViewController){
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sign in to iCloud" message:@"You must sign in to your iCloud account to post your Rides so that other users can Match.\nOn the Home screen, launch the Settings App, tap \"iCloud\", and enter your Apple ID.  Then turn \"iCloud Drive\" on and allow this App to store data.\nIf you don't have an iCloud account, tap \"Create a new Apple ID\"."
                                    preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                    
                    [parameters setObject:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"TimeOfLastAlert"];
                    
                }
            });
        }else {
            
            //   check which data has changed.  update all that has changed.
            //   go through each Ride one at a time. - I guess there will be a parameters 'icloudrides' to compare.  when successful, update that icloud rides.
            
            // here is what should be saved:
            //  create a CLLocation object and save it  home and work
            //   create NSDate objects for arrive start, end and leave start, end and save them
            //   daysofweek nsnumber
            //   datepostedtoicloud - that's now
            
            // also the 0 record has....
            
            
     //       NSLog(@"here y");
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            CKContainer *defaultContainer=[CKContainer defaultContainer];
            CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
            
            
            
            
            int recordID=[[parameters objectForKey:@"iCloudRecordID"] intValue];
            
      //      NSLog(@"here y %i",recordID);
            if(recordID==0){
       //         NSLog(@"got a 0");
                srandom(randomNumber);
                randomNumber= abs( (int)random());
                randomNumber=randomNumber%1000000;
                if(randomNumber<100001)randomNumber=randomNumber+100001;
                //  between 100,001 and 999,999
                NSString *trialRecordIDName=[NSString stringWithFormat:@"%i0",randomNumber];
                CKRecordID *trialRecordID=[[CKRecordID alloc] initWithRecordName:trialRecordIDName];
                [publicDatabase fetchRecordWithID:trialRecordID completionHandler:^(CKRecord *fetchedRecord, NSError *error){
                    if([error code]==CKErrorUnknownItem){  //  no such record exists, create it
                        // NOT AN ERROR
                        [parameters setObject:[NSNumber numberWithInt:randomNumber] forKey:@"iCloudRecordID"];
            //            NSLog(@"got a valid recordID");
                        // [self getInitialSubscription];
                        
                        [self pushMyDataToCloud];  // will have a recordID!=0 this time around
                        
                    }else if (!error){
                   //     NSLog(@"trying a new number");
                        [self pushMyDataToCloud];// try a new random number for the trialRecordID
                    }else{
                        // NSLog(@"error in icloud 3745947");
                        [self iCloudErrorMessage:@"There was an error (2) trying to post your Rides for other users to Match.  Please try again later."];
                    }
                }];
                return;  // will this work?
            }
      //      NSLog(@"continuing after getting a valid recordID  %i",recordID);
            NSMutableArray *recordIDs=[[NSMutableArray alloc] initWithCapacity:5];
            for (int I=0;I<=5;I++){
                [recordIDs addObject:[[CKRecordID alloc] initWithRecordName:[NSString stringWithFormat:@"%i%i",recordID,I]]];
            }
            CKFetchRecordsOperation *fetchRecords=[[CKFetchRecordsOperation alloc] initWithRecordIDs:recordIDs];
            fetchRecords.fetchRecordsCompletionBlock= ^(NSDictionary *recordsByRecordID,NSError *error){
                if(error){
                    if(error.code==CKErrorPartialFailure)error=nil;
                }
                if(error){
                    int seconds=0;
                    if(error.code==CKErrorServiceUnavailable || error.code==CKErrorRequestRateLimited)
                        seconds=[[[error userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                    if(seconds>0){
                        [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue (1) trying to post your Rides for other users to Match.  Please try again after %i seconds.",seconds]];
                    }else{
                     //   NSLog(@"error is %ld   %@",(long)error.code,error);
                        
                        [self iCloudErrorMessage:@"There was an error (1) trying to post your Rides for other users to Match.  Please try again later."];
                    }
                    
                }else{
                    
                    NSMutableArray *theRecordsToSave=[[NSMutableArray alloc] initWithCapacity:5];
                    NSMutableArray *theRecordsToDelete=[[NSMutableArray alloc] initWithCapacity:5];
                    
                    CKRecord *zerothRecord=[recordsByRecordID objectForKey:[recordIDs objectAtIndex:0]];
                    if(!zerothRecord){
                        zerothRecord=[[CKRecord alloc] initWithRecordType:@"Rides" recordID:[recordIDs objectAtIndex:0]];
                   //     NSLog(@"here 11111");
                    }
                    //  [zerothRecord setValue:@"45" forKey:@"DaysOfTheWeek"];
                    [theRecordsToSave addObject:zerothRecord];
                    for(int I=1;I<=5;I++){
                        CKRecord *aRecord=[recordsByRecordID objectForKey:[recordIDs objectAtIndex:I]];
                        NSDictionary *aRide=[[parameters objectForKey:@"TheRides"] objectAtIndex:I-1];
                        if(![aRide objectForKey:@"GeoA"]){
                            if(aRecord)[theRecordsToDelete addObject:[recordIDs objectAtIndex:I]];
                        }else{
                            if(!aRecord){
                                aRecord=[[CKRecord alloc] initWithRecordType:@"Rides" recordID:[recordIDs objectAtIndex:I]];
                        //        NSLog(@"here 11112");
                            }
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
                            CLLocation *home=[[CLLocation alloc] initWithLatitude:[[aRide objectForKey:@"GeoAlat"] doubleValue] longitude:[[aRide objectForKey:@"GeoA"] doubleValue]];
                            [aRecord setObject:home forKey:@"HomeLocation"];  // a CLLocation object
                            
                            
                            [theRecordsToSave addObject:aRecord];
                       //     NSLog(@"want to save these records:  %@",aRecord);
                        }
                    }
                    if([theRecordsToDelete count] +[theRecordsToSave count]>0){
                //        NSLog(@"and here is the complete set %@   and deleting these:  %@",theRecordsToSave,theRecordsToDelete);
                        CKModifyRecordsOperation *modifyRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:theRecordsToSave recordIDsToDelete:theRecordsToDelete];
                        //   modifyRecords.savePolicy=CKRecordSaveAllKeys;
                        modifyRecords.modifyRecordsCompletionBlock=^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
                            
                            if(operationError){
                                if(operationError.code==CKErrorPartialFailure){
                            //        NSLog(@"a partial error?????    %@",operationError);
                                    operationError=nil;
                                }
                            }
                            if(operationError){
                                
                                int seconds=0;
                                if(operationError.code==CKErrorServiceUnavailable || operationError.code==CKErrorRequestRateLimited)
                                    seconds=[[[operationError userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                                if(seconds>0){
                                    [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to post your Rides for other users to Match.  Please try again after %i seconds.",seconds]];
                                }else{
                               //     NSLog(@"the error was  %@",operationError);
                                    [self iCloudErrorMessage:@"There was an error trying to post your Rides for other users to Match.  Please try again later."];
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
                    }else{
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                            [parameters setObject:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"TimeOfLastUpdate"];
                            [self titleForMatchNearA:@"Match times       ."];
                        });
                        
                    }
                }
            };
            [publicDatabase addOperation:fetchRecords];
        }
    }];
    
    
}

-(void)redrawScreen{
  
    locationA.hidden=![theSelectedRide objectForKey:@"GeoA"];
    locationB.hidden=NO;
    
    if([theSelectedRide objectForKey:@"GeoA"])
        [locationA setTitle:@"Show 'Home'" forState:UIControlStateNormal];
    
    if([theSelectedRide objectForKey:@"GeoB"]){
        [locationB setTitle:@"Show 'Work'" forState:UIControlStateNormal];
    }else{
        [locationB setTitle:@"Show Princeton" forState:UIControlStateNormal];
    }
    
    
    [leaveTimes setTitle:
     [NSString stringWithFormat:@"%@ - %@",[theSelectedRide objectForKey:@"LeaveStart"],[theSelectedRide objectForKey:@"LeaveEnd"]]
                forState:UIControlStateNormal];
    [arriveTimes setTitle:
     [NSString stringWithFormat:@"%@ - %@",[theSelectedRide objectForKey:@"ArriveStart"],[theSelectedRide objectForKey:@"ArriveEnd"]]
                 forState:UIControlStateNormal];
    
    if(![theSelectedRide objectForKey:@"LeaveStart"]){
        leaveB.hidden=YES;
        leaveTimes.hidden=YES;
    }else{
        leaveB.hidden=NO;
        leaveTimes.hidden=NO;
    }
    if(![theSelectedRide objectForKey:@"ArriveStart"]){
        arriveB.hidden=YES;
        arriveTimes.hidden=YES;
        
    }else{
        arriveB.hidden=NO;
        arriveTimes.hidden=NO;
    }

    int myCarOrYours=0;
    if ([theSelectedRide objectForKey:@"MyCarOrYours"]) {
        myCarOrYours=[[theSelectedRide objectForKey:@"MyCarOrYours"] intValue];
    }
    [myCarOrYoursControl setSelectedSegmentIndex:myCarOrYours];
    
    int daysOfTheWeek=0;
    if([theSelectedRide objectForKey:@"DaysOfTheWeek"])
        daysOfTheWeek=[[theSelectedRide objectForKey:@"DaysOfTheWeek"] intValue];
    UIColor *upperCaseColor=[UIColor colorWithRed:0 green:0. blue:0. alpha:1];
    UIColor *lowerCaseColor=[UIColor colorWithRed:0 green:0. blue:0. alpha:.5];
    if(daysOfTheWeek>=64){
        [Sunday setTitle:@"S" forState:UIControlStateNormal];
        [Sunday setTitleColor:upperCaseColor forState:UIControlStateNormal];
        daysOfTheWeek=daysOfTheWeek-64;
    }else{
        [Sunday setTitle:@"s" forState:UIControlStateNormal];
        [Sunday setTitleColor:lowerCaseColor forState:UIControlStateNormal];
    }
    if(daysOfTheWeek>=32){
        [Saturday setTitle:@"S" forState:UIControlStateNormal];
        [Saturday setTitleColor:upperCaseColor forState:UIControlStateNormal];
        daysOfTheWeek=daysOfTheWeek-32;
    }else{
        [Saturday setTitle:@"s" forState:UIControlStateNormal];
        [Saturday setTitleColor:lowerCaseColor forState:UIControlStateNormal];
    }
    if(daysOfTheWeek>=16){
        [Friday setTitle:@"F" forState:UIControlStateNormal];
        [Friday setTitleColor:upperCaseColor forState:UIControlStateNormal];
        daysOfTheWeek=daysOfTheWeek-16;
    }else{
        [Friday setTitle:@"f" forState:UIControlStateNormal];
        [Friday setTitleColor:lowerCaseColor forState:UIControlStateNormal];
    }
    if(daysOfTheWeek>=8){
        [Thursday setTitle:@"T" forState:UIControlStateNormal];
        [Thursday setTitleColor:upperCaseColor forState:UIControlStateNormal];
        daysOfTheWeek=daysOfTheWeek-8;
    }else{
        [Thursday setTitle:@"t" forState:UIControlStateNormal];
        [Thursday setTitleColor:lowerCaseColor forState:UIControlStateNormal];
    }
    if(daysOfTheWeek>=4){
        [Wednesday setTitle:@"W" forState:UIControlStateNormal];
        [Wednesday setTitleColor:upperCaseColor forState:UIControlStateNormal];
        daysOfTheWeek=daysOfTheWeek-4;
    }else{
        [Wednesday setTitle:@"w" forState:UIControlStateNormal];
        [Wednesday setTitleColor:lowerCaseColor forState:UIControlStateNormal];
    }
    if(daysOfTheWeek>=2){
        [Tuesday setTitle:@"T" forState:UIControlStateNormal];
        [Tuesday setTitleColor:upperCaseColor forState:UIControlStateNormal];
        daysOfTheWeek=daysOfTheWeek-2;
    }else{
        [Tuesday setTitle:@"t" forState:UIControlStateNormal];
        [Tuesday setTitleColor:lowerCaseColor forState:UIControlStateNormal];
    }
    if(daysOfTheWeek>=1){
        [Monday setTitle:@"M" forState:UIControlStateNormal];
        [Monday setTitleColor:upperCaseColor forState:UIControlStateNormal];
    }else{
        [Monday setTitle:@"m" forState:UIControlStateNormal];
        [Monday setTitleColor:lowerCaseColor forState:UIControlStateNormal];
    }
    
    
}

-(NSString *)daysOverlapYours:(int)yourDaysOfWeek mine:(int)myDaysOfTheWeek{
    
    NSString *MTWTFSS=@"";
    NSString *MaybeYesNo=@"";
    NSString *yes=@"✓ ";
    NSString *no=@"x ";
    NSString *noMatter=@"- ";
    
    if (yourDaysOfWeek>=64){
        yourDaysOfWeek=yourDaysOfWeek-64;
        MTWTFSS=[@"S" stringByAppendingString:MTWTFSS];
        if (myDaysOfTheWeek>=64){
            MaybeYesNo=[yes stringByAppendingString:MaybeYesNo];
            myDaysOfTheWeek=myDaysOfTheWeek-64;
        }else{
            MaybeYesNo=[no stringByAppendingString:MaybeYesNo];
        }
    }else if(myDaysOfTheWeek>=64){
        MaybeYesNo=[no stringByAppendingString:MaybeYesNo];
        MTWTFSS=[@"s" stringByAppendingString:MTWTFSS];
        myDaysOfTheWeek=myDaysOfTheWeek-64;
    }else{
        MaybeYesNo=[noMatter stringByAppendingString:MaybeYesNo];
        MTWTFSS=[@"s" stringByAppendingString:MTWTFSS];
    }
    
    
    if (yourDaysOfWeek>=32){
        yourDaysOfWeek=yourDaysOfWeek-32;
        MTWTFSS=[@"S" stringByAppendingString:MTWTFSS];
        if (myDaysOfTheWeek>=32){
            MaybeYesNo=[yes stringByAppendingString:MaybeYesNo];
            myDaysOfTheWeek=myDaysOfTheWeek-32;
        }else{
            MaybeYesNo=[no stringByAppendingString:MaybeYesNo];
        }
    }else if(myDaysOfTheWeek>=32){
        MaybeYesNo=[no stringByAppendingString:MaybeYesNo];
        MTWTFSS=[@"s" stringByAppendingString:MTWTFSS];
        myDaysOfTheWeek=myDaysOfTheWeek-32;
    }else{
        MaybeYesNo=[noMatter stringByAppendingString:MaybeYesNo];
        MTWTFSS=[@"s" stringByAppendingString:MTWTFSS];
    }
    
    if (yourDaysOfWeek>=16){
        yourDaysOfWeek=yourDaysOfWeek-16;
        MTWTFSS=[@"F" stringByAppendingString:MTWTFSS];
        if (myDaysOfTheWeek>=16){
            MaybeYesNo=[yes stringByAppendingString:MaybeYesNo];
            myDaysOfTheWeek=myDaysOfTheWeek-16;
        }else{
            MaybeYesNo=[no stringByAppendingString:MaybeYesNo];
        }
    }else if(myDaysOfTheWeek>=16){
        MaybeYesNo=[no stringByAppendingString:MaybeYesNo];
        MTWTFSS=[@"f" stringByAppendingString:MTWTFSS];
        myDaysOfTheWeek=myDaysOfTheWeek-16;
    }else{
        MaybeYesNo=[noMatter stringByAppendingString:MaybeYesNo];
        MTWTFSS=[@"f" stringByAppendingString:MTWTFSS];
    }
    
    if (yourDaysOfWeek>=8){
        yourDaysOfWeek=yourDaysOfWeek-8;
        MTWTFSS=[@"T" stringByAppendingString:MTWTFSS];
        if (myDaysOfTheWeek>=8){
            MaybeYesNo=[yes stringByAppendingString:MaybeYesNo];
            myDaysOfTheWeek=myDaysOfTheWeek-8;
        }else{
            MaybeYesNo=[no stringByAppendingString:MaybeYesNo];
        }
    }else if(myDaysOfTheWeek>=8){
        MaybeYesNo=[no stringByAppendingString:MaybeYesNo];
        MTWTFSS=[@"t" stringByAppendingString:MTWTFSS];
        myDaysOfTheWeek=myDaysOfTheWeek-8;
    }else{
        MaybeYesNo=[noMatter stringByAppendingString:MaybeYesNo];
        MTWTFSS=[@"t" stringByAppendingString:MTWTFSS];
    }
    
    if (yourDaysOfWeek>=4){
        yourDaysOfWeek=yourDaysOfWeek-4;
        MTWTFSS=[@"W" stringByAppendingString:MTWTFSS];
        if (myDaysOfTheWeek>=4){
            MaybeYesNo=[yes stringByAppendingString:MaybeYesNo];
            myDaysOfTheWeek=myDaysOfTheWeek-4;
        }else{
            MaybeYesNo=[no stringByAppendingString:MaybeYesNo];
        }
    }else if(myDaysOfTheWeek>=4){
        MaybeYesNo=[no stringByAppendingString:MaybeYesNo];
        MTWTFSS=[@"w" stringByAppendingString:MTWTFSS];
        myDaysOfTheWeek=myDaysOfTheWeek-4;
    }else{
        MaybeYesNo=[noMatter stringByAppendingString:MaybeYesNo];
        MTWTFSS=[@"w" stringByAppendingString:MTWTFSS];
    }
    
    if (yourDaysOfWeek>=2){
        yourDaysOfWeek=yourDaysOfWeek-2;
        MTWTFSS=[@"T" stringByAppendingString:MTWTFSS];
        if (myDaysOfTheWeek>=2){
            MaybeYesNo=[yes stringByAppendingString:MaybeYesNo];
            myDaysOfTheWeek=myDaysOfTheWeek-2;
        }else{
            MaybeYesNo=[no stringByAppendingString:MaybeYesNo];
        }
    }else if(myDaysOfTheWeek>=2){
        MaybeYesNo=[no stringByAppendingString:MaybeYesNo];
        MTWTFSS=[@"t" stringByAppendingString:MTWTFSS];
        myDaysOfTheWeek=myDaysOfTheWeek-2;
    }else{
        MaybeYesNo=[noMatter stringByAppendingString:MaybeYesNo];
        MTWTFSS=[@"t" stringByAppendingString:MTWTFSS];
    }
    
    if (yourDaysOfWeek>=1){
        MTWTFSS=[@"M" stringByAppendingString:MTWTFSS];
        if (myDaysOfTheWeek>=1){
            MaybeYesNo=[yes stringByAppendingString:MaybeYesNo];
        }else{
            MaybeYesNo=[no stringByAppendingString:MaybeYesNo];
        }
    }else if(myDaysOfTheWeek>=1){
        MaybeYesNo=[no stringByAppendingString:MaybeYesNo];
        MTWTFSS=[@"m" stringByAppendingString:MTWTFSS];
    }else{
        MaybeYesNo=[noMatter stringByAppendingString:MaybeYesNo];
        MTWTFSS=[@"m" stringByAppendingString:MTWTFSS];
    }
    
    return [MTWTFSS stringByAppendingString:MaybeYesNo];
    
}

-(int)overLapIntervalsStart:(NSString *)Start End:(NSString *)End OtherStart:(NSString *)otherStart OtherEnd:(NSString *)otherEnd{
    double myStart=[[dateFormat dateFromString:Start] timeIntervalSinceReferenceDate];
    double myEnd=[[dateFormat dateFromString:End] timeIntervalSinceReferenceDate];
    double yourEnd=[[dateFormat dateFromString:otherEnd] timeIntervalSinceReferenceDate];
    double yourStart=[[dateFormat dateFromString:otherStart] timeIntervalSinceReferenceDate];
    
    if(myStart>myEnd){
        if(myStart>yourEnd){
            myStart=myStart-24*3600;
        }else{
            myEnd=myEnd+24*3600;
        }
    }
    if(yourStart>yourEnd){
        if(yourStart>myEnd){
            yourStart=yourStart-24*3600;
        }else{
            yourEnd=yourEnd+24*3600;
        }
    }
    
    int startOverlap=9.0*(yourStart-myStart)/(myEnd-myStart)+.9999;  // if 100 then its ok!
    int endOverlap=9.0*(yourEnd-myStart)/(myEnd-myStart)+1.0001;
    if (startOverlap<0)startOverlap=0;
    if(startOverlap>10)startOverlap=10;
    if(endOverlap<0)endOverlap=0;
    if(endOverlap>10)endOverlap=10;
    
    return startOverlap*100+endOverlap;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    
//    NSLog(@"the selected ann is %@",view.annotation.title);
    
    
    if([theSelectedAnnotation isEqualToString:@"Home"]){
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(deselectHome) object:nil];
        theHomeAnnotationView.layer.zPosition=-1;
    }
    if([theSelectedAnnotation isEqualToString:@"Work"]){
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(deselectWork) object:nil];
        theWorkAnnotationView.layer.zPosition=-1;
    }
    
    theSelectedAnnotation=view.annotation.title;
    
    if (([theSelectedAnnotation isEqualToString:@"Work"] && !theWorkAnnotationView.canShowCallout)||
        ([theSelectedAnnotation isEqualToString:@"Home"] && !theHomeAnnotationView.canShowCallout)
        ){
        theSelectedAnnotation=@"none";
        [mapIt deselectAnnotation:view.annotation animated:YES];
        float squareSize=13;
        if(filterData.isOn)squareSize=25;
        CGPoint theCenterPoint=CGPointMake(100,100);
        CLLocationCoordinate2D centerCoordinate=[mapIt convertPoint:theCenterPoint toCoordinateFromView:mapIt];
        CGPoint theTopLeft=CGPointMake(theCenterPoint.x-squareSize, theCenterPoint.y-squareSize);
        CLLocationCoordinate2D topLeftCoordinate=[mapIt convertPoint:theTopLeft toCoordinateFromView:mapIt];
        
        MKMapPoint mapPoint1=MKMapPointForCoordinate(topLeftCoordinate);
        MKMapPoint mapPoint2=MKMapPointForCoordinate(centerCoordinate);
        float newEdgeDistance=.707*sqrt((mapPoint1.x-mapPoint2.x)*(mapPoint1.x-mapPoint2.x) +
                                        (mapPoint1.y-mapPoint2.y)*(mapPoint1.y-mapPoint2.y));
        
        CLLocationCoordinate2D annotationCoordinate=view.annotation.coordinate;
        MKMapPoint mapPoint3=MKMapPointForCoordinate(annotationCoordinate);
        MKMapRect aRect=MKMapRectMake(mapPoint3.x-newEdgeDistance, mapPoint3.y-newEdgeDistance,newEdgeDistance*2, newEdgeDistance*2);
        NSSet *overlapAnnotations=[mapIt annotationsInMapRect:aRect];
        
    //    NSLog(@"the number of overlaps is %lu",(unsigned long)[overlapAnnotations count]);
        
        if([overlapAnnotations count]>1){
            NSEnumerator *enumerator = [overlapAnnotations objectEnumerator];
            id <MKAnnotation>value;
            while ((value = [enumerator nextObject])) {
                if(![value.title isEqualToString:@"Work"] && ![value.title isEqualToString:@"Home"])
                    theSelectedAnnotation=value.title;
            }
        }
    }
        
    
        
    if(theSelectedAnnotation.length>5 && !requestFromAlert && ![theSelectedAnnotation containsString:@","]){
        
        requestFromAlert=NO;
        theAnnotationTitleArray=[NSArray arrayWithObject:theSelectedAnnotation];
        entriesInAGroup.hidden=NO;
        [entriesInAGroup scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]atScrollPosition:UITableViewScrollPositionTop animated:NO];
        [entriesInAGroup reloadData];
        [mapIt deselectAnnotation:view.annotation animated:YES];
        
        
        
        
        
        
        
        
    }else if([theSelectedAnnotation isEqualToString:@"Work"] && theWorkAnnotationView.canShowCallout){
        requestFromAlert=NO;
        
        [self performSelector:@selector(deselectWork) withObject:nil afterDelay:4.0f];
    }else if([theSelectedAnnotation isEqualToString:@"Home"]  && theHomeAnnotationView.canShowCallout){
        requestFromAlert=NO;
        
        [self performSelector:@selector(deselectHome) withObject:nil afterDelay:4.0f];
    }else if ([theSelectedAnnotation containsString:@","] && !requestFromAlert ){
        requestFromAlert=NO;
        
        
    
        NSArray *theTitles=[[theSelectedAnnotation componentsSeparatedByString:@", "] sortedArrayUsingComparator:^(id obj1, id obj2){
            NSString *object1=obj1;
            NSString *object2=obj2;
            if(object1.length<5 || object2.length<5)return (NSComparisonResult)NSOrderedSame;
            if([[object1 substringToIndex:4] isEqualToString:[object2 substringToIndex:4]]){
                if([[object1 substringFromIndex:4] intValue]>[[object2 substringFromIndex:4] intValue])return (NSComparisonResult)NSOrderedDescending;
                return (NSComparisonResult)NSOrderedAscending;
            }else{
                if([[object1 substringToIndex:4] isEqualToString:@"Home"])return (NSComparisonResult)NSOrderedDescending;
                return (NSComparisonResult)NSOrderedAscending;
            }
        }];
        
        
        
        NSString *theLocations=@"";
        for(NSString *buttonTitle in theTitles) {
            theLocations=[theLocations stringByAppendingFormat:@", %@",buttonTitle];
        }
  //      theLocations=[theLocations substringFromIndex:2];
 //       theAnnotationTitleString=theLocations;
        theAnnotationTitleArray=theTitles;
        entriesInAGroup.hidden=NO;
        [entriesInAGroup scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]atScrollPosition:UITableViewScrollPositionTop animated:NO];
        [entriesInAGroup reloadData];
        [mapIt deselectAnnotation:view.annotation animated:YES];
        
    }else{
        requestFromAlert=NO;
        
    }
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if([theAnnotationTitleArray count]==1){
        if([indexPath row]==0 && filterData.isOn)return 60;
        return 30;
    }
    return 60;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if([theAnnotationTitleArray count]==1 && filterData.isOn)return 4;
    if([theAnnotationTitleArray count]==1 )return 3;
    return ([theAnnotationTitleArray count]+1);
}



-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *textCellIndentifier=@"TextCell";
    
    UITableViewCell *cell;
    cell=[tableView dequeueReusableCellWithIdentifier:textCellIndentifier];
    if(cell==nil)cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:textCellIndentifier];
    cell.textLabel.font=[UIFont systemFontOfSize:16];
    
 //   NSLog(@"the subview count is %lu",(unsigned long)cell.contentView.subviews.count);

    cell.imageView.image=nil;
    cell.textLabel.textAlignment=NSTextAlignmentCenter;
    if([indexPath row]<[theAnnotationTitleArray count] && ([theAnnotationTitleArray count]>1 || filterData.isOn)){
        NSString *theEntry=[theAnnotationTitleArray objectAtIndex:[indexPath row]];
        if(theEntry.length>5)
            cell.textLabel.text=[NSString stringWithFormat:@"#%@ (%@)",[theEntry substringFromIndex:5],[theEntry substringToIndex:4]];
        
        
        if(filterData.isOn){
            
            if([theAnnotationTitleArray count]==1)
                cell.textLabel.text=[NSString stringWithFormat:@"Match #%@",[theEntry substringFromIndex:5]];
            float widthNumber=24;
            float shiftNumber=3;
            float heightNumber=20;
            if (theEntry.length>6)shiftNumber=-1;
            float width=48.0;
            float height=19.0;
            float heightDays=6;  //   just for the days colored at the top
            
            
            CGSize size = CGSizeMake(width+4, height*2+heightDays+8);
            UIGraphicsBeginImageContext(size);
            [[UIColor colorWithRed:.0 green:.0 blue:.0 alpha:1.0] setFill];
            UIRectFill(CGRectMake(0,0,size.width,size.height));//  borders
            NSMutableArray *colorForEachDay=[[NSMutableArray alloc] initWithCapacity:7];
            int arriveRedYellow=10;
            int arriveYellowGreen=0;
            int arriveGreenYellow=10;
            int arriveYellowRed=0;
            int leaveRedYellow=10;
            int leaveYellowGreen=0;
            int leaveGreenYellow=10;
            int leaveYellowRed=0;
            int temp=0;
            int temp1=0;
            BOOL atLeastOneIsGreen=NO;
            BOOL thisOneIsGreen=YES;
            NSDictionary *theSelection=[[theSelectedRide objectForKey:@"Nearby50"] objectAtIndex:[[theEntry substringFromIndex:5] intValue]-1];
            NSString *MTWTFSSMaybeYesNo=[self daysOverlapYours:[[theSelection objectForKey:@"DaysOfTheWeek"] intValue] mine:[[theSelectedRide objectForKey:@"DaysOfTheWeek"] intValue]];
            for (int day=0;day<7;day++){
                NSString *result=[[MTWTFSSMaybeYesNo substringFromIndex:7+day*2] substringToIndex:1];
                [colorForEachDay addObject:result];
                if([result isEqualToString:@"x"])thisOneIsGreen=NO;
            }
            int results=[self overLapIntervalsStart:[theSelectedRide objectForKey:@"ArriveStart"] End:[theSelectedRide objectForKey:@"ArriveEnd"] OtherStart:[theSelection objectForKey:@"ArriveStart"]  OtherEnd:[theSelection objectForKey:@"ArriveEnd"]];
            //            return startOverlap*1000+endOverlap;
            
            
            //results is 1010   first two are red-green    and last two are green-red
            temp=results/100;  //0-10
            
            if(temp<arriveRedYellow)arriveRedYellow=temp;
            if(temp>arriveYellowGreen)arriveYellowGreen=temp;
            if(temp==10)thisOneIsGreen=NO;
            
            temp=results%100;
            if(temp<arriveGreenYellow)arriveGreenYellow=temp;
            if(temp>arriveYellowRed)arriveYellowRed=temp;
            if(temp==0)thisOneIsGreen=NO;
            
            results=[self overLapIntervalsStart:[theSelectedRide objectForKey:@"LeaveStart"] End:[theSelectedRide objectForKey:@"LeaveEnd"] OtherStart:[theSelection objectForKey:@"LeaveStart"]  OtherEnd:[theSelection objectForKey:@"LeaveEnd"]];
            //            return startOverlap*1000+endOverlap;
            
            temp1=results/100;
            if(temp1<leaveRedYellow)leaveRedYellow=temp1;
            if(temp1>leaveYellowGreen)leaveYellowGreen=temp1;
            if(temp1==10)thisOneIsGreen=NO;
            temp1=results%100;
            if(temp1<leaveGreenYellow)leaveGreenYellow=temp1;
            if(temp1>leaveYellowRed)leaveYellowRed=temp1;
            if(temp1==0)thisOneIsGreen=NO;
            if(thisOneIsGreen)atLeastOneIsGreen=YES;
            
      //      NSLog(@"the divisions occur here   temp=%i    temp1=%i",temp,temp1);
            
            for(int day=0;day<7;day++){
                UIColor *theColor=[UIColor greenColor];
                if([[colorForEachDay objectAtIndex:day] isEqualToString:@"x"]){
                    theColor=[UIColor redColor];
                }else if([[colorForEachDay objectAtIndex:day] isEqualToString:@"-"]){
                    theColor=[UIColor whiteColor];
                }else if([[colorForEachDay objectAtIndex:day] isEqualToString:@"Y"]){
                    theColor=[UIColor yellowColor];
                }
                [theColor setFill];
                UIRectFill(CGRectMake(2+day*(width+1)/7,2,(width+1)/7-1,heightDays));
            }
            
            [[UIColor redColor] setFill];
            UIRectFill(CGRectMake(2,heightDays+4,arriveRedYellow*width/10.0,height));
            [[UIColor yellowColor] setFill];
            UIRectFill(CGRectMake(2+arriveRedYellow*width/10.0,heightDays+4, (arriveYellowGreen-arriveRedYellow)*width/10.0, height));
            [[UIColor greenColor] setFill];
            UIRectFill(CGRectMake(2+arriveYellowGreen*width/10.0,heightDays+4, (arriveGreenYellow-arriveYellowGreen)*width/10.0, height));
            [[UIColor yellowColor] setFill];
            UIRectFill(CGRectMake(2+arriveGreenYellow*width/10.0,heightDays+4, (arriveYellowRed-arriveGreenYellow)*width/10.0, height));
            [[UIColor redColor] setFill];
            UIRectFill(CGRectMake(2+arriveYellowRed*width/10.0,heightDays+4, width-arriveYellowRed*width/10.0, height));
            
            
            [[UIColor redColor] setFill];
            UIRectFill(CGRectMake(2,heightDays+6+height,leaveRedYellow*width/10.0,height));
            [[UIColor yellowColor] setFill];
            UIRectFill(CGRectMake(2+leaveRedYellow*width/10.0,heightDays+6+height, (leaveYellowGreen-leaveRedYellow)*width/10.0, height));
            [[UIColor greenColor] setFill];
            UIRectFill(CGRectMake(2+leaveYellowGreen*width/10.0,heightDays+6+height, (leaveGreenYellow-leaveYellowGreen)*width/10.0, height));
            [[UIColor yellowColor] setFill];
            UIRectFill(CGRectMake(2+leaveGreenYellow*width/10.0,heightDays+6+height, (leaveYellowRed-leaveGreenYellow)*width/10.0, height));
            [[UIColor redColor] setFill];
            UIRectFill(CGRectMake(2+leaveYellowRed*width/10.0,heightDays+6+height,width-leaveYellowRed*width/10.0,height));
            
            [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0] setFill];
            UIRectFill(CGRectMake((width-widthNumber)/2+2,heightDays+height-heightNumber/2+5,widthNumber,heightNumber));
            
            
            if(atLeastOneIsGreen){
                [[UIColor colorWithRed:.7 green:1.0 blue:.7 alpha:1.0] setFill];
                if ([[theEntry substringToIndex:4] isEqualToString: @"Work"]){
                    [[UIColor colorWithRed:0 green:.4 blue:0.0 alpha:1.0] setFill];
                }
            }else{
                [[UIColor whiteColor] setFill];
                if([[theEntry substringToIndex:4] isEqualToString: @"Work"]){
                    [[UIColor blackColor] setFill];
                }
                
            }
            UIRectFill(CGRectMake((width-widthNumber)/2+4,heightDays+height-heightNumber/2+7,widthNumber-4,heightNumber-4));
            NSString *theTitle=[theEntry substringFromIndex:5];  // Work, Work 1
            
            
            UIColor *textColor=[UIColor blackColor];
            if([[theEntry substringToIndex:4] isEqualToString: @"Work"]){
                textColor=[UIColor whiteColor];
            }
            
            
            [theTitle
             drawInRect:CGRectMake((width-widthNumber)/2+7+shiftNumber,heightDays+height-heightNumber/2+6,widthNumber-6,heightNumber-4)withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:textColor,NSForegroundColorAttributeName,[UIFont boldSystemFontOfSize:14],NSFontAttributeName, nil]];
            
            
            
            
            
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            cell.imageView.image=image;
            
            
            UIGraphicsEndImageContext();
            
        }
        
            
        
    }else if([theAnnotationTitleArray count]==1){
        long row=[indexPath row]+1;
        if(filterData.isOn)row--;
        if(row==2)cell.textLabel.text=@"Send Message";
        if(row==1){
            NSString *theEntry=[theAnnotationTitleArray objectAtIndex:0];
            NSDictionary *theSelection=[[theSelectedRide objectForKey:@"Nearby50"] objectAtIndex:[[theEntry substringFromIndex:5] intValue]-1];
                
            if ([[theEntry substringToIndex:4] isEqualToString:@"Work"]){
                cell.textLabel.text=[NSString stringWithFormat:@"Show #%@ (Home)",[[theAnnotationTitleArray objectAtIndex:0] substringFromIndex:5]];
            }else if ([theSelection objectForKey:@"GeoB"]){
                cell.textLabel.text=[NSString stringWithFormat:@"Show #%@ (Work)",[[theAnnotationTitleArray objectAtIndex:0] substringFromIndex:5]];
            }else{
                cell.textLabel.text=[NSString stringWithFormat:@"No #%@ (Work)",[[theAnnotationTitleArray objectAtIndex:0] substringFromIndex:5]];
            }
        }
        if(row==3)cell.textLabel.text=@"Ok";
    }else{
        cell.textLabel.text=@"Cancel";
    }
    return cell;
}


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
    tableView.hidden=YES;
    
    long row=[indexPath row]+1;
    if(filterData.isOn)row--;
    
    if([indexPath row]<[theAnnotationTitleArray count] && [theAnnotationTitleArray count]>1){
        
        requestFromAlert=NO;
        theAnnotationTitleArray=[NSArray arrayWithObject:[theAnnotationTitleArray objectAtIndex:[indexPath row]]];
        entriesInAGroup.hidden=NO;
        [entriesInAGroup scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]atScrollPosition:UITableViewScrollPositionTop animated:NO];
        [entriesInAGroup reloadData];
        
        
    }else if([theAnnotationTitleArray count]>1){
        
    }else if (row==2){
     //   NSUserDefaults *localDefaults=[NSUserDefaults standardUserDefaults];
        [parameters setObject:iDNumberSelected forKey:@"Match ID"];
        self.tabBarController.selectedIndex=3;
    }else if (row==1){
        NSString *theEntry=[theAnnotationTitleArray objectAtIndex:0];
        NSDictionary *theSelection=[[theSelectedRide objectForKey:@"Nearby50"] objectAtIndex:[[theEntry substringFromIndex:5] intValue]-1];
        
        if ([[theEntry substringToIndex:4] isEqualToString:@"Work"] || [theSelection objectForKey:@"GeoB"]){
            
            //  need to find this single entry (actually 'home' and 'work' replaced, in a current annotation somewhere.  currentannotations could be multiple annotations seperated by a comma.
            NSArray *currentAnnotations=[mapIt annotations];
            NSString *whatToShow=theEntry;
       //     NSLog(@"what to show %@",whatToShow);
            whatToShow=[whatToShow stringByReplacingOccurrencesOfString:@"Home" withString:@"Wrk"];
            whatToShow=[whatToShow stringByReplacingOccurrencesOfString:@"Work" withString:@"Home"];
            whatToShow=[whatToShow stringByReplacingOccurrencesOfString:@"Wrk" withString:@"Work"];
        //    NSLog(@"what to show %@",whatToShow);
            NSString *whatToShowComma=[whatToShow stringByAppendingString:@","];
            
            for (int I=0;I<[currentAnnotations count] ; I++) {
                NSString *currentTitle=[[currentAnnotations objectAtIndex:I] title];
            //    NSLog(@"the currentTitle is %@",currentTitle);
                if(currentTitle.length<6 || currentTitle.length<whatToShow.length)currentTitle=@"this is a longer title"; //  in both cases it doesn't contain whatToShow so just preven crashes
                if([currentTitle containsString:whatToShowComma] ||
                   //  it is at the end of the string
                   [[currentTitle substringFromIndex:(currentTitle.length-whatToShow.length)] isEqualToString:whatToShow]){
                    //solves:
                    //   but "Work 12, HOme 3"   contains "Work 1"
                    //   as does "Work 12, Work 1"
                    //  so look for "Work 1," and if it is not their see if the string ends with "....Work 1"
                    
                    
                    
                    requestFromAlert=YES;
                    [mapIt selectAnnotation:[currentAnnotations objectAtIndex:I] animated:YES];
                    MKPointAnnotation *theAnnotation=[currentAnnotations objectAtIndex:I];
                    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(theAnnotation.coordinate,mapIt.region.span.latitudeDelta*1000/.009006, mapIt.region.span.longitudeDelta*1000/.014);
                    
                    [mapIt setRegion:region animated:YES];
                    
                    [self performSelector:@selector(deselectAnnotation:) withObject:[currentAnnotations objectAtIndex:I] afterDelay:3.0f];
                    break;
                    
                }
            }
            
        }
    }
    
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 40;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if([theAnnotationTitleArray count]==1 && [[UIScreen mainScreen] bounds].size.height>480)return 150;
    if([theAnnotationTitleArray count]==1 )return 135;
    return  80;
}
- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    if([theAnnotationTitleArray count]>1){
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 80)];
        //    headerLabel.backgroundColor= [UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1.0];
        
        headerLabel.numberOfLines=8;
        headerLabel.textAlignment=NSTextAlignmentCenter;// UITextAlignmentCenter;
        headerLabel.font=[UIFont boldSystemFontOfSize:16.0];
        headerLabel.text=[NSString stringWithFormat:@"Ride Share Information\nMultiple Locations\n\nSelect Match location:"];
        return headerLabel;
    }else{
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 150)];
        //    headerLabel.backgroundColor= [UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1.0];
        
        headerLabel.numberOfLines=16;
        headerLabel.textAlignment=NSTextAlignmentCenter;// UITextAlignmentCenter;
        headerLabel.font=[UIFont boldSystemFontOfSize:12.0];
       
        
        if(!theAnnotationTitleArray)return headerLabel;
        
        NSString *theLocation=[theAnnotationTitleArray objectAtIndex:0];
   //     NSLog(@"here with the request for %@",theLocation);
        
        NSDictionary *theSelection=[[theSelectedRide objectForKey:@"Nearby50"] objectAtIndex:[[theLocation substringFromIndex:5] intValue]-1];

        
        NSString *arriveStart=[theSelection objectForKey:@"ArriveStart"];
        NSString *arriveEnd=[theSelection objectForKey:@"ArriveEnd"];
        NSString *leaveStart=[theSelection objectForKey:@"LeaveStart"];
        NSString *leaveEnd=[theSelection objectForKey:@"LeaveEnd"];
        //        NSString *daysOfWeek=[theSelection objectForKey:@"DaysOfTheWeek"];
        NSString *yes=@"✓";
        NSString *no=@"x ";
        NSString *noMatter=@"- ";
        iDNumberSelected=[NSString stringWithFormat:@"%i-%@",[[theSelection objectForKey:@"IDNumber"]  intValue]/10,[[@"0ABCDE!!!!!!!" substringFromIndex:[[theSelection objectForKey:@"IDNumber"]  intValue]%10] substringToIndex:1]];
        int yourDaysOfWeek= [[theSelection objectForKey:@"DaysOfTheWeek"] intValue];
        int myDaysOfTheWeek=[[theSelectedRide objectForKey:@"DaysOfTheWeek"] intValue];
      
        
        NSString *MTWTFMaybeYesNo=[self daysOverlapYours:yourDaysOfWeek mine:myDaysOfTheWeek];
        
        int theirChoice=[[theSelection objectForKey:@"MyCarOrYours"] intValue];
        int myCarChoice=[[theSelectedRide objectForKey:@"MyCarOrYours"] intValue];
        NSString *yourCarChoice=@"My car";  // they want to use my car because they checked 'not my car'
        if (theirChoice==0)yourCarChoice=@"Their car";  // they want to use their car because they checked 'my car'
        if (theirChoice==2)yourCarChoice=@"Either";
        NSString *carOverlap=yes;
        if(theirChoice==0 && myCarChoice==0)carOverlap=no;
        if(theirChoice==1 && myCarChoice==1)carOverlap=no;
        
        
        CLLocation *home=[[CLLocation alloc] initWithLatitude:[[theSelectedRide objectForKey:@"GeoAlat"] doubleValue] longitude:[[theSelectedRide objectForKey:@"GeoA"] doubleValue]];
        CLLocation *yourHome=[[CLLocation alloc] initWithLatitude:[[theSelection objectForKey:@"GeoAlat"] doubleValue] longitude:[[theSelection objectForKey:@"GeoA"] doubleValue]];
        NSString *homeDistance=[NSString stringWithFormat:@"%2.1f miles",[home distanceFromLocation:yourHome]*39.37/(5280*12)];
        
        NSString *workDistance=@"        -         ";
        if([theSelectedRide objectForKey:@"GeoB"] && [theSelection objectForKey:@"GeoB"]){
            CLLocation *work=[[CLLocation alloc] initWithLatitude:[[theSelectedRide objectForKey:@"GeoBlat"] doubleValue] longitude:[[theSelectedRide objectForKey:@"GeoB"] doubleValue]];
            CLLocation *yourWork=[[CLLocation alloc] initWithLatitude:[[theSelection objectForKey:@"GeoBlat"] doubleValue] longitude:[[theSelection objectForKey:@"GeoB"] doubleValue]];
            workDistance=[NSString stringWithFormat:@"%2.1f miles",[work distanceFromLocation:yourWork]*39.37/(5280*12)];
        }
        
        
        
        NSString *arrivalOverlaps=noMatter;
        NSString *leaveOverlaps=noMatter;
        if(arriveStart){
            if([theSelectedRide objectForKey:@"ArriveStart"]){
                
                int results=[self overLapIntervalsStart:[theSelectedRide objectForKey:@"ArriveStart"] End:[theSelectedRide objectForKey:@"ArriveEnd"] OtherStart:arriveStart OtherEnd:arriveEnd];
                arrivalOverlaps=yes;
                if(results>1000 || results==0) arrivalOverlaps=no;
                
                
            }else{
                arrivalOverlaps=no; //  you want it and I don't
            }
        }else{
            arriveEnd=@"    ";
            arriveStart=@"    ";
            if([theSelectedRide objectForKey:@"ArriveStart"])
                arrivalOverlaps=no; //  I want it and you don't
        }
        if(leaveStart){
            if([theSelectedRide objectForKey:@"LeaveStart"]){
                
                int results=[self overLapIntervalsStart:[theSelectedRide objectForKey:@"LeaveStart"] End:[theSelectedRide objectForKey:@"LeaveEnd"] OtherStart:leaveStart OtherEnd:leaveEnd];
                leaveOverlaps=yes;
                if(results>=1000 || results==0) leaveOverlaps=no;
            }else{
                leaveOverlaps=no; //  you want it and I don't
            }
        }else{
            leaveEnd=@"    ";
            leaveStart=@"    ";
            if([theSelectedRide objectForKey:@"LeaveStart"])
                leaveOverlaps=no; //  I want it and you don't
        }
        
        
        
  //      float shift=([[UIScreen mainScreen] bounds].size.height-480)/2;//568
  //      if (shift<0)shift=0;
        
        
        NSString *skipLines=@"\n";
        if([[UIScreen mainScreen] bounds].size.height>480)skipLines=@"\n\n";
        
        headerLabel.text=[NSString stringWithFormat:@"Ride Share Information%@Match #%@ (%@)\nID: %@\nArrive: %@ - %@   %@\nLeave: %@ - %@   %@\n%@   %@\nCar: %@                    %@  \nHome separation: %@\nWork separation: %@",skipLines,[theLocation substringFromIndex:5],[theLocation substringToIndex:4] ,iDNumberSelected, arriveStart,arriveEnd,arrivalOverlaps,leaveStart,leaveEnd,leaveOverlaps,[MTWTFMaybeYesNo substringToIndex:7],[MTWTFMaybeYesNo substringFromIndex:7],yourCarChoice,carOverlap, homeDistance,workDistance];
        
        return headerLabel;
        
        
    }
}


-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    
    float squareSize=9;
    if(filterData.isOn)squareSize=25;
    CGPoint theCenterPoint=CGPointMake(100,100);
    CLLocationCoordinate2D centerCoordinate=[mapIt convertPoint:theCenterPoint toCoordinateFromView:mapIt];
    CGPoint theTopLeft=CGPointMake(theCenterPoint.x-squareSize, theCenterPoint.y-squareSize);
    CLLocationCoordinate2D topLeftCoordinate=[mapIt convertPoint:theTopLeft toCoordinateFromView:mapIt];

    MKMapPoint mapPoint1=MKMapPointForCoordinate(topLeftCoordinate);
    MKMapPoint mapPoint2=MKMapPointForCoordinate(centerCoordinate);
    float newEdgeDistance=.707*sqrt((mapPoint1.x-mapPoint2.x)*(mapPoint1.x-mapPoint2.x) +
                                (mapPoint1.y-mapPoint2.y)*(mapPoint1.y-mapPoint2.y));
    
    
 //   NSLog(@"   %f   %f   the title is ",edgeDistance,newEdgeDistance);
    if(fabs(edgeDistance-newEdgeDistance)/(fabs(edgeDistance)+.1)>.01){
        NSString *theList=@""; // list of annotations to explore for re-adding overlaps
        NSArray *currentAnnotations=mapIt.annotations;
        NSMutableArray *addTheseAnnotations=[[NSMutableArray alloc] init];
        NSMutableArray *removeTheseAnnotations=[[NSMutableArray alloc] init];
        
        if(edgeDistance>newEdgeDistance){  // edge has become shorter, break up groups, create a list
            for (int I=0;I<[currentAnnotations count]; I++) {
                NSString *theTitle=[[currentAnnotations objectAtIndex:I] title];
                if([theTitle rangeOfString:@", "].length>0){
                    
                    
              //      NSLog(@"the Title is %@",theTitle);
                    
                    // title is Home 3, Work 2, Home 12, Home, Work
                    //    remove the group annotation
                    //    break up title and add individual annotations from myAnnotations.
                    //    also add to list
                    
                    theList=[theList stringByAppendingFormat:@"%@; ",[theTitle stringByReplacingOccurrencesOfString:@"," withString:@";"]];
                            // @"Home 1; Work 2, Home, Work; "
                    [removeTheseAnnotations addObject:[currentAnnotations objectAtIndex:I]];
                    NSArray *theTitles=[theTitle componentsSeparatedByString:@", "];
                    for (int J=0; J<[theTitles count]; J++) {
                        NSString *aTitle=[theTitles objectAtIndex:J];
                        int homeWorkShift=0;
                        if(aTitle.length>=4)
                            if([[aTitle substringToIndex:4] isEqualToString:@"Home"])homeWorkShift=1;
                        if(aTitle.length>5){
                            int matchNumber=[[aTitle substringFromIndex:5] intValue]-1;
                            [addTheseAnnotations addObject:[myAnnotations objectAtIndex:matchNumber*2+homeWorkShift]];
                     /*   }else if(homeWorkShift==0){
                             [addTheseAnnotations addObject:myWork];
                        }else{
                            [addTheseAnnotations addObject:myHome];*/
                        }
                    }
                }
            }
            
            //theList is "Home 1; Work 2, Home, Work; "  these annotations are in addTheseAnnotations and the groups are in removeTheseAnnotations
            if([removeTheseAnnotations count]>0)[mapIt removeAnnotations:removeTheseAnnotations];
            if([addTheseAnnotations count]>0)[mapIt addAnnotations:addTheseAnnotations];
            [removeTheseAnnotations removeAllObjects];
            [addTheseAnnotations removeAllObjects];
        }else{     // edge is longer, test all annotations for new overlaps
        //    NSLog(@"here .....");
            for (int I=0;I<[currentAnnotations count]; I++){
                NSString *addThis=[[currentAnnotations objectAtIndex:I] title];
                if(![addThis isEqualToString:@"Home"] && ![addThis isEqualToString:@"Work"])
                    theList=[theList stringByAppendingFormat:@"%@; ",addThis];
            }
            
            
       //     NSLog(@"the list is %@",theList);
           // theList=[theList stringByAppendingString:@"Home, Work, "];
            //theList is "Home 1, Work 2, Home, Work, "
        }
        edgeDistance=newEdgeDistance;
        
        
        if(theList.length>0){
           currentAnnotations=mapIt.annotations;  // a new list
            NSMutableArray *theTitlesAndIndexes=[[NSMutableArray alloc] initWithCapacity:[currentAnnotations count]];
            for (int I=0;I<[currentAnnotations count]; I++) {
                [theTitlesAndIndexes addObject:
                 [NSDictionary dictionaryWithObjectsAndKeys:[[currentAnnotations objectAtIndex:I] title],@"title",[NSNumber numberWithInteger:I],@"currentAnnotation index",nil]];
            }
            
            
            
            NSMutableArray *testTheseAnnotations=[[NSMutableArray alloc] initWithArray:[theList componentsSeparatedByString:@"; "]];  // this breaks up the group
            //   it will be {@"Work 1",@"Home 2, Home, Work",@" "}  or {""}
            //test the annotations that are in theList
            for (int I=0;I<[theTitlesAndIndexes count]; I++) {
                NSString *currentTitle=[[theTitlesAndIndexes objectAtIndex:I] objectForKey:@"title"];
                
                
                
                
                
                if([testTheseAnnotations containsObject:currentTitle]){
           //         NSLog(@"testing");
                    CLLocationCoordinate2D annotationCoordinate=
                        [[currentAnnotations objectAtIndex:
                            [[[theTitlesAndIndexes objectAtIndex:I] objectForKey:@"currentAnnotation index"] integerValue]]
                        coordinate];
                    double numberOfElementsInGroup=[[currentTitle componentsSeparatedByString:@","] count];
                    double totalGroupLatitude=annotationCoordinate.latitude*numberOfElementsInGroup;
                    double totalGroupLongitude=annotationCoordinate.longitude*numberOfElementsInGroup;
                    MKMapPoint mapPoint2=MKMapPointForCoordinate(annotationCoordinate);
                    MKMapRect aRect=MKMapRectMake(mapPoint2.x-edgeDistance*2, mapPoint2.y-edgeDistance*2,edgeDistance*4, edgeDistance*4);
                    NSSet *overlapAnnotations=[mapIt annotationsInMapRect:aRect];
                    if([overlapAnnotations count]>1){  //  includes an annotation other than itself
             //           NSLog(@"found overlaps %lu",(unsigned long)[overlapAnnotations count]);
                        
                        // test for overalps.
                        //  check to be sure the overlaps are included in testTheseAnnotations
                        //     if they overlap with annotations included in testTheseAnnotations,
                        //          add each one to removeTheseAnnotations
                        //          add a group to addTheseAnnotations
                        //          remove the individual annotations from testTheseAnnotations
                        //                 so they won't be included in other groups
                        //                   i.i. if (1 overlaps 2 but not 3)  and (2 overlaps 3) 1-2 is a group at 1, and 2-3 is not a group
                        
                        NSString *newTitle=@"";
                        NSEnumerator *enumerator = [overlapAnnotations objectEnumerator];
                        id <MKAnnotation>value;
                        while ((value = [enumerator nextObject])) {
                            if([testTheseAnnotations containsObject:value.title] && ![value.title isEqualToString:currentTitle]){
                                newTitle=[newTitle stringByAppendingFormat:@", %@",value.title];
                                [removeTheseAnnotations addObject:value];  // might be myHome or myWork
                                double additionalElements=[[value.title componentsSeparatedByString:@","] count];
                                numberOfElementsInGroup=numberOfElementsInGroup + additionalElements;
                                totalGroupLatitude=totalGroupLatitude+value.coordinate.latitude*additionalElements;
                                totalGroupLongitude=totalGroupLongitude+value.coordinate.longitude*additionalElements;
                                [testTheseAnnotations removeObject:value.title];
                 //               NSLog(@"removed %@",value.title);
                            }
                        }
                        
                        //  newTitle is ""  or ", Home 2, Work 3, Home, Work"
                        // constructed by adding titles, some of which mat=y have ,'s in them
                        
                        if(newTitle.length>0){
                            newTitle=[currentTitle  stringByAppendingString:newTitle];
                            // //  newTitle is "Home 3, Home 2, Work 3, Home, Work"
                            
                            
                            
                            //   need to sort newtitle...
                            
                            NSArray *sortedArray =[[newTitle componentsSeparatedByString:@", "] sortedArrayUsingComparator:^(id obj1, id obj2){
                                NSString *object1=obj1;
                                NSString *object2=obj2;
                                if(object1.length<5 || object2.length<5)return (NSComparisonResult)NSOrderedSame;
                                if([[object1 substringToIndex:4] isEqualToString:[object2 substringToIndex:4]]){
                                    if([[object1 substringFromIndex:4] intValue]>[[object2 substringFromIndex:4] intValue])return (NSComparisonResult)NSOrderedDescending;
                                    return (NSComparisonResult)NSOrderedAscending;
                                }else{
                                    if([[object1 substringToIndex:4] isEqualToString:@"Home"])return (NSComparisonResult)NSOrderedDescending;
                                    return (NSComparisonResult)NSOrderedAscending;
                                }
                            }];
                            newTitle=@"";
                            for(NSString *aTitle in sortedArray) {
                                newTitle=[newTitle stringByAppendingFormat:@", %@",aTitle];
                            }
                            newTitle=[newTitle substringFromIndex:2];
                            
                            
                            
                            
                            
                            MKPointAnnotation *anAnnotation=[[MKPointAnnotation alloc] init];
                            anAnnotation.title=newTitle;
                            anAnnotation.coordinate=CLLocationCoordinate2DMake(totalGroupLatitude/numberOfElementsInGroup, totalGroupLongitude/numberOfElementsInGroup);
                            [addTheseAnnotations addObject:anAnnotation];
                            [removeTheseAnnotations addObject:[currentAnnotations objectAtIndex:
                                                               [[[theTitlesAndIndexes objectAtIndex:I] objectForKey:@"currentAnnotation index"] integerValue]]]; // might be myHome or myWork
                        }
                    }
                    [testTheseAnnotations removeObject:currentTitle];
                }
            }
        }
        
        if([removeTheseAnnotations count]>0)[mapIt removeAnnotations:removeTheseAnnotations];
        if([addTheseAnnotations count]>0)[mapIt addAnnotations:addTheseAnnotations];
        
        
    }
    
    
}

-(void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views{
    for (MKAnnotationView *view in views){
        if([[[view annotation] title] isEqualToString:@"Home"]){
            view.layer.zPosition=-1;
            theHomeAnnotationView=view;
            //[[view superview] sendSubviewToBack:view];
        }else if([[[view annotation] title] isEqualToString:@"Work"]){
            view.layer.zPosition=-1;
            theWorkAnnotationView=view;
           // [[view superview] sendSubviewToBack:view];
        }else{
            view.layer.zPosition=0;
         //   [[view superview] bringSubviewToFront:view];
        }
    }
}


- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>) annotation{
    
    
    
    
    MKAnnotationView *pinView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"pinView"];
    
 //   NSLog(@"doing it again is there a pinview?");
    
    if (!pinView)
        pinView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pinView"];
    
 //   NSLog(@"annotation title  %@",annotation.title);
    
    if([annotation.title isEqualToString:@"Home"]){
        pinView.image=[UIImage imageNamed:@"53-house white on black"];
        pinView.centerOffset=CGPointMake(-2, -5);
      //  pinView.enabled=NO;
      //  theHomeAnnotationView=pinView;
       // pinView.enabled=NO;
        pinView.canShowCallout=NO;
    ////    [[UIImage imageNamed:@"53-house blue.png"] drawAtPoint:CGPointMake(0,10)];//30)];
    }else if([annotation.title isEqualToString:@"Work"]){
        pinView.image=[UIImage imageNamed:@"177-building black on white"];
        pinView.centerOffset=CGPointMake(-2, -5);
     //   pinView.enabled=NO;
     //   theWorkAnnotationView=pinView;
       // pinView.enabled=NO;
        
         pinView.canShowCallout=NO;
        
    }else if(annotation.title.length>5){
        
        float widthNumber=24;
        float shiftNumber=3;
        float heightNumber=20;
        if (annotation.title.length>6)shiftNumber=-1;
        
        if(filterData.isOn){
            
            
            float width=48.0;
            float height=19.0;
            float heightDays=6;  //   just for the days colored at the top
            
            
            CGSize size = CGSizeMake(width+4, height*2+heightDays+8);
            pinView.centerOffset=CGPointMake(0,-4);
            UIGraphicsBeginImageContext(size);
            [[UIColor colorWithRed:.0 green:.0 blue:.0 alpha:1.0] setFill];
            UIRectFill(CGRectMake(0,0,size.width,size.height));//  borders
            
            
            
            
        //from below -     [[annotation.title substringFromIndex:5]drawInRect:CGRectMake(5+shiftNumber,1,widthNumber-6,heightNumber-4) withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],NSForegroundColorAttributeName,[UIFont boldSystemFontOfSize:14],NSFontAttributeName, nil]];
            
            NSMutableArray *colorForEachDay=[[NSMutableArray alloc] initWithCapacity:7];
            NSArray *theRidesToDisplay=[annotation.title componentsSeparatedByString:@", "];
            int arriveRedYellow=10*width;
            int arriveYellowGreen=0;
            int arriveGreenYellow=10*width;
            int arriveYellowRed=0;
            int leaveRedYellow=10*width;
            int leaveYellowGreen=0;
            int leaveGreenYellow=10*width;
            int leaveYellowRed=0;
            int temp=0;
            int temp1=0;
            BOOL atLeastOneHomeIsGreen=NO;
            BOOL atLeastOneWorkIsGreen=NO;
            for (int I=0; I<[theRidesToDisplay count]; I++) {
                BOOL thisOneIsGreen=YES;
                NSDictionary *theSelection=[[theSelectedRide objectForKey:@"Nearby50"] objectAtIndex:[[[theRidesToDisplay objectAtIndex:I] substringFromIndex:5] intValue]-1];
                NSString *MTWTFSSMaybeYesNo=[self daysOverlapYours:[[theSelection objectForKey:@"DaysOfTheWeek"] intValue] mine:[[theSelectedRide objectForKey:@"DaysOfTheWeek"] intValue]];
                for (int day=0;day<7;day++){
                    NSString *result=[[MTWTFSSMaybeYesNo substringFromIndex:7+day*2] substringToIndex:1];
                    if(I==0){
                        [colorForEachDay addObject:result];
                    }else if (![[colorForEachDay objectAtIndex:day] isEqualToString:result]){
                        [colorForEachDay setObject:@"Y" atIndexedSubscript:day];
                    }
                    if([result isEqualToString:@"x"])thisOneIsGreen=NO; // requires all days to be ok
                }
                
                
                int results=[self overLapIntervalsStart:[theSelectedRide objectForKey:@"ArriveStart"] End:[theSelectedRide objectForKey:@"ArriveEnd"] OtherStart:[theSelection objectForKey:@"ArriveStart"]  OtherEnd:[theSelection objectForKey:@"ArriveEnd"]];
                //            return startOverlap*1000+endOverlap;
                
                temp=results/100;  //0-10
                if(temp<arriveRedYellow)arriveRedYellow=temp;
                if(temp>arriveYellowGreen)arriveYellowGreen=temp;
                if(temp==10)thisOneIsGreen=NO;
                temp=results%100;
                if(temp<arriveGreenYellow)arriveGreenYellow=temp;
                if(temp>arriveYellowRed)arriveYellowRed=temp;
                if(temp==0)thisOneIsGreen=NO;
                
                
                results=[self overLapIntervalsStart:[theSelectedRide objectForKey:@"LeaveStart"] End:[theSelectedRide objectForKey:@"LeaveEnd"] OtherStart:[theSelection objectForKey:@"LeaveStart"]  OtherEnd:[theSelection objectForKey:@"LeaveEnd"]];
                //            return startOverlap*1000+endOverlap;
                
                temp1=results/100;
                if(temp1<leaveRedYellow)leaveRedYellow=temp1;
                if(temp1>leaveYellowGreen)leaveYellowGreen=temp1;
                if(temp1==10)thisOneIsGreen=NO;
                temp1=results%100;
                if(temp1<leaveGreenYellow)leaveGreenYellow=temp1;
                if(temp1>leaveYellowRed)leaveYellowRed=temp1;
                if(temp1==0)thisOneIsGreen=NO;
                
                
                if(thisOneIsGreen && [[[theRidesToDisplay objectAtIndex:I] substringToIndex:4] isEqualToString:@"Home"])atLeastOneHomeIsGreen=YES;
                if(thisOneIsGreen && [[[theRidesToDisplay objectAtIndex:I] substringToIndex:4] isEqualToString:@"Work"])atLeastOneWorkIsGreen=YES;
            }
            
            
            for(int day=0;day<7;day++){
                UIColor *theColor=[UIColor greenColor];
                if([[colorForEachDay objectAtIndex:day] isEqualToString:@"x"]){
                    theColor=[UIColor redColor];
                }else if([[colorForEachDay objectAtIndex:day] isEqualToString:@"-"]){
                    theColor=[UIColor whiteColor];
                }else if([[colorForEachDay objectAtIndex:day] isEqualToString:@"Y"]){
                    theColor=[UIColor yellowColor];
                }
                [theColor setFill];
                UIRectFill(CGRectMake(2+day*(width+1)/7,2,(width+1)/7-1,heightDays));
            }
            
            [[UIColor redColor] setFill];
            UIRectFill(CGRectMake(2,heightDays+4,arriveRedYellow*width/10.0,height));
            [[UIColor yellowColor] setFill];
            UIRectFill(CGRectMake(2+arriveRedYellow*width/10.0,heightDays+4, (arriveYellowGreen-arriveRedYellow)*width/10.0, height));
            [[UIColor greenColor] setFill];
            UIRectFill(CGRectMake(2+arriveYellowGreen*width/10.0,heightDays+4, (arriveGreenYellow-arriveYellowGreen)*width/10.0, height));
            [[UIColor yellowColor] setFill];
            UIRectFill(CGRectMake(2+arriveGreenYellow*width/10.0,heightDays+4, (arriveYellowRed-arriveGreenYellow)*width/10.0, height));
            [[UIColor redColor] setFill];
            UIRectFill(CGRectMake(2+arriveYellowRed*width/10.0,heightDays+4, width-arriveYellowRed*width/10.0, height));
            
            
            [[UIColor redColor] setFill];
            UIRectFill(CGRectMake(2,heightDays+6+height,leaveRedYellow*width/10.0,height));
            [[UIColor yellowColor] setFill];
            UIRectFill(CGRectMake(2+leaveRedYellow*width/10.0,heightDays+6+height, (leaveYellowGreen-leaveRedYellow)*width/10.0, height));
            [[UIColor greenColor] setFill];
             UIRectFill(CGRectMake(2+leaveYellowGreen*width/10.0,heightDays+6+height, (leaveGreenYellow-leaveYellowGreen)*width/10.0, height));
            [[UIColor yellowColor] setFill];
            UIRectFill(CGRectMake(2+leaveGreenYellow*width/10.0,heightDays+6+height, (leaveYellowRed-leaveGreenYellow)*width/10.0, height));
            [[UIColor redColor] setFill];
            UIRectFill(CGRectMake(2+leaveYellowRed*width/10.0,heightDays+6+height,width-leaveYellowRed*width/10.0,height));
            
            
            
            
        
            
            
            [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0] setFill];
            UIRectFill(CGRectMake((width-widthNumber)/2+2,heightDays+height-heightNumber/2+5,widthNumber,heightNumber));
            
            if(atLeastOneHomeIsGreen){
                [[UIColor colorWithRed:.7 green:1.0 blue:.7 alpha:1.0] setFill];
                if(atLeastOneWorkIsGreen){
                    [[UIColor colorWithRed:0 green:200/255. blue:0.0 alpha:1.0] setFill];
                }
            }else if (atLeastOneWorkIsGreen){
                [[UIColor colorWithRed:0 green:.4 blue:0.0 alpha:1.0] setFill];
            }else{
                 [[UIColor whiteColor] setFill];
                if([annotation.title containsString:@"Work"]){
                    [[UIColor blackColor] setFill];
                    if([annotation.title containsString:@"Home"]){
                         [[UIColor lightGrayColor] setFill];
                    }
                }
                
//                [[UIColor colorWithRed:0 green:210/255. blue:1.0 alpha:1.0] setFill];
            }
            UIRectFill(CGRectMake((width-widthNumber)/2+4,heightDays+height-heightNumber/2+7,widthNumber-4,heightNumber-4));
            NSString *theTitle=[annotation.title substringFromIndex:5];  // Work, Work 1
            if([annotation.title containsString:@","]){
                theTitle=@"M";
                shiftNumber=1;
            }
            
            UIColor *textColor=[UIColor blackColor];
            if([annotation.title containsString:@"Work"]  &&
               (!atLeastOneHomeIsGreen ||atLeastOneWorkIsGreen )){
                textColor=[UIColor whiteColor];
                
                        
           //     if([annotation.title containsString:@"Home"]){
             //       textColor=[UIColor blackColor];
               // }
            }
            
            [theTitle
             drawInRect:CGRectMake((width-widthNumber)/2+7+shiftNumber,heightDays+height-heightNumber/2+6,widthNumber-6,heightNumber-4)withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:textColor,NSForegroundColorAttributeName,[UIFont boldSystemFontOfSize:14],NSFontAttributeName, nil]];
            
            
            
            
            
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            pinView.image=image;
            pinView.canShowCallout = YES;
            
            
            
        }else{  // just numbers, not match display
            CGSize size = CGSizeMake(widthNumber, heightNumber);
            UIGraphicsBeginImageContext(size);
            [[UIColor colorWithRed:.0 green:.0 blue:.0 alpha:1.0] setFill];
            UIRectFill(CGRectMake(0,0,widthNumber,heightNumber));
            
            
            UIColor *textColor=[UIColor blackColor];
            [[UIColor whiteColor] setFill];
            if([annotation.title containsString:@"Work"]){
                textColor=[UIColor whiteColor];
                [[UIColor blackColor] setFill];
                if([annotation.title containsString:@"Home"]){
                    textColor=[UIColor blackColor];
                    [[UIColor lightGrayColor] setFill];
                }
            }
            
            
            
        //    [[UIColor colorWithRed:0 green:210/255. blue:1.0 alpha:1.0] setFill];
       
            UIRectFill(CGRectMake(2,2,widthNumber-4, heightNumber-4));
            
            NSString *theTitle=[annotation.title substringFromIndex:5];  // Work, Work 1
            if([annotation.title containsString:@","]){
                theTitle=@"M";
                shiftNumber=1;
            }

            
            
            
        //    textColor=[UIColor whiteColor];
            
            
            
            
            [theTitle
               drawInRect:CGRectMake(5+shiftNumber,1,widthNumber-6,heightNumber-4) withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:textColor,NSForegroundColorAttributeName,[UIFont boldSystemFontOfSize:14],NSFontAttributeName, nil]];
            
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            pinView.image=image;
            pinView.canShowCallout = YES;
            pinView.centerOffset=CGPointMake(0, 0);
        }
     
    
    
    }



    
    return pinView;
}

-(void)deselectHome{
    if([theSelectedAnnotation isEqualToString:@"Home"]){
        [mapIt deselectAnnotation:myHome animated:YES];
        theSelectedAnnotation=@"none";
    }
    theHomeAnnotationView.layer.zPosition=-1;
    
  //  theHomeAnnotationView.enabled=NO;
}

-(void)deselectWork{
    if([theSelectedAnnotation isEqualToString:@"Work"]){
        [mapIt deselectAnnotation:myWork animated:YES];
        theSelectedAnnotation=@"none";
    }
    theWorkAnnotationView.layer.zPosition=-1;
 //   theWorkAnnotationView.enabled=NO;
}

-(void)deselectAnnotation:(id)theAnnotation{
        [mapIt deselectAnnotation:theAnnotation animated:YES];
}

-(IBAction)matchNearA:(id)sender{
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Need 'Home' location to Match" message:@"You need to set your 'Home' location\nfor this Ride on the \"My Info\" page\nto find a Ride Share Match\nleaving from, or returning to,\na location near your 'Home'.\nTo set your 'Home' location, tap the \"My Info\" tab below then tap \"Set 'Home'\".\n(Alternatively, just tap \"Do that now\" below.)\nFinally, locate and tap\nyour 'Home' location on the map." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Do that now" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        
     //   NSUserDefaults *localDefaults=[NSUserDefaults standardUserDefaults];
        [parameters setObject:@"yes" forKey:@"Set 'Home' location"];
        self.tabBarController.selectedIndex=1;
        
    }];
    [alert addAction:defaultAction];
    UIAlertAction* defaultAction1 = [UIAlertAction actionWithTitle:@"Maybe later" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction1];
    [self presentViewController:alert animated:YES completion:nil];
    
}


-(IBAction)infoButton:(id)sender{
    ChoicesViewController *choices = [[ChoicesViewController alloc] initWithNibName:@"ChoicesViewController" bundle:nil];
    [choices selectionIs:6];
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:choices];
    navigationController.modalPresentationStyle=UIModalPresentationFormSheet;
    navigationController.navigationBar.tintColor=[UIColor colorWithRed:.9 green:.0 blue:0 alpha:1.0];
    
    [self presentViewController:navigationController animated:YES completion:nil];
    
}

-(IBAction)changeSelectedRide:(id)sender{  // can be called with sender==nil
    tapMatchForInfo.hidden=YES;
    
    [parameters setObject:[NSNumber numberWithLong:rideSelector.selectedSegmentIndex] forKey:@"RideSelected"];
    entriesInAGroup.hidden=YES;
    
    
    BOOL getDataRequest=NO;
    
    
    if([[getDataOrStop imageForState:UIControlStateNormal] isEqual:[UIImage imageNamed:@"X image 21.png"]]){
 //       NSLog(@"Cancel data download");
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        //   stop the downloading somehow
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
//        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(packageDataAndProceed) object:nil];
        [self titleForMatchNearA:@"Match times       ."];  // is this wrong!!!!!
        
        
        if([sender isEqual:getDataOrStop]){   // cancel the current data download request and be done
            return;  //   don't do this method, just do the cancel
        }else{   // cancel an earlier data download request and make a new one
            // anything else need to happen if returning to this screen or changing ride while data is being downloaded?
        }
        
    }else if([sender isEqual:getDataOrStop]){  // it is a circle and it was tapped
        getDataRequest=YES;  // just like in a viewWillAppear but insist that data is downloaded
    }else if([parameters objectForKey:@"Show Match"]){
        getDataRequest=YES;  // just like in a viewWillAppear but insist that data is downloaded
        [filterData setOn:NO];
    }
    
    
 //   NSLog(@"Ride changed");
    
    
    //this is the old ride:
    NSArray *oldNearby50=[theSelectedRide objectForKey:@"Nearby50"];
    double oldHomeLong=[[theSelectedRide objectForKey:@"GeoA"] doubleValue];
    double oldHomeLat=[[theSelectedRide objectForKey:@"GeoAlat"] doubleValue];

    if([theSelectedRide objectForKey:@"GeoA"])[mapIt removeAnnotation:myHome];
    if([theSelectedRide objectForKey:@"GeoB"])[mapIt removeAnnotation:myWork];

    NSDate *oldTimeLastLoaded=[NSDate dateWithTimeIntervalSinceNow:-1000]; // old init value
    if([theSelectedRide objectForKey:@"TimeLastDownloaded"])
        oldTimeLastLoaded=[theSelectedRide objectForKey:@"TimeLastDownloaded"];
    
    
    //this is now the new ride:
    theSelectedRide=[theRides objectAtIndex:[rideSelector selectedSegmentIndex]];
    
    CLLocation *newHome=[[CLLocation alloc] initWithLatitude:[[theSelectedRide objectForKey:@"GeoAlat"] doubleValue] longitude:[[theSelectedRide objectForKey:@"GeoA"] doubleValue]];
    CLLocation *oldHome=[[CLLocation alloc] initWithLatitude:oldHomeLat longitude:oldHomeLong];
    double homeDistance=[newHome distanceFromLocation:oldHome]*39.37/(5280*12);
    
    if(![theSelectedRide objectForKey:@"TimeLastDownloaded"])
        [theSelectedRide setObject:[NSDate dateWithTimeIntervalSinceNow:-1000] forKey:@"TimeLastDownloaded"];
    
    getDataOrStop.hidden=NO;
    if(![theSelectedRide objectForKey:@"GeoA"]){  // no home location set
        
        
   //     NSLog(@"here ssss");
        [self titleForMatchNearA:@"Set Home!"];
        [self matchNearA:nil];
        
        if([mapIt.annotations count]>0){
            [mapIt removeAnnotations:mapIt.annotations];
            [myAnnotations removeAllObjects];
        }
        
    }else if(getDataRequest ||
             
             ([[theSelectedRide objectForKey:@"TimeLastDownloaded"] timeIntervalSinceNow]<-600
       
       &&   (homeDistance>.1   ||   [oldTimeLastLoaded timeIntervalSinceNow]<-600 ) )
             
             ){
        //  Need new data.  It is a new data request or elese
        //                Data is old and either (last data is old or last home was too far away)
        
        
        
        [self titleForMatchNearA:@"Downloading..."];

        
        // don't do this if there is no cloudkit access ;  what data should I use????
        if([mapIt.annotations count]>0){
            [mapIt removeAnnotations:mapIt.annotations];
            [myAnnotations removeAllObjects];
        }
        
        
        
        //  this is the entry to cloudkit:
        
        if([parameters objectForKey:@"Show Match"]){
            [self downloadMatchData];
        }else{
            [self downloadData];
        }
        
        
        
    }else if([[theSelectedRide objectForKey:@"TimeLastDownloaded"] timeIntervalSinceNow]<
        [oldTimeLastLoaded timeIntervalSinceNow] && homeDistance<=.1){
        
        // changed to a new ride close to last home with older data, transfer the newer data from the last home and the time mark stamp
        //last time is better and the distances are close.  use last data
        //   no need to redo the graph if the filter isn't on
        
        [theSelectedRide setObject:oldNearby50 forKey:@"Nearby50"];
        [theSelectedRide setObject:oldTimeLastLoaded forKey:@"TimeLastDownloaded"];
        
        
        [self titleForMatchNearA:@"Match times       ." ];
        
        
        
    }else {
        //   the data has changed,  the new data was downloaded within the last 10 minutes
        //   either the new data is more recent than the last data or the new home is too far from the last home
        [self titleForMatchNearA:@"Match times       ." ];
     
        
    }
 //   NSLog(@"the selected ride is %@",theSelectedRide);
    
    
    [self redrawScreen];
    
//    [self saveDefaults];
    
}

-(void)showAllRides{
   
    for(int I=0;I<[[theSelectedRide objectForKey:@"Nearby50"] count];I++){
        NSDictionary *thisRide=[[theSelectedRide objectForKey:@"Nearby50"] objectAtIndex:I];
        MKPointAnnotation *anAnnotation=[[MKPointAnnotation alloc] init];
        anAnnotation.title=[NSString stringWithFormat:@"Home %i",(I+1)];
        anAnnotation.coordinate=CLLocationCoordinate2DMake([[thisRide objectForKey:@"GeoAlat"] doubleValue], [[thisRide objectForKey:@"GeoA"] doubleValue]);
        MKPointAnnotation *aWorkAnnotation=[[MKPointAnnotation alloc] init];
        aWorkAnnotation.title=[NSString stringWithFormat:@"Work %i",(I+1)];
        aWorkAnnotation.coordinate=CLLocationCoordinate2DMake([[thisRide objectForKey:@"GeoBlat"] doubleValue], [[thisRide objectForKey:@"GeoB"] doubleValue]);
        
        
        // what if location is not given???   need to add something to array but....
        

        //  2 for each annotation in the results....
        //    the number will be assigned based on this.
        //   but do i need to add the annotation above????
        //     do all results have a home and work location?
        
        
        
        [myAnnotations addObject:aWorkAnnotation];
        [myAnnotations addObject:anAnnotation];
        
        
    }
    [mapIt addAnnotations:myAnnotations];
    
    
 //   NSLog(@"here showing all rides   %lu",(unsigned long)myAnnotations.count);
    tapMatchForInfo.hidden=(myAnnotations.count==0);
    
    
}

-(IBAction)matchRides:(id)sender{
 //   NSLog(@"match Rides....");
    entriesInAGroup.hidden=YES;
    tapMatchForInfo.hidden=YES;
    if([mapIt.annotations count]>0){
        [mapIt removeAnnotations:mapIt.annotations];
        [myAnnotations removeAllObjects];
    }
    
 //   if(![theSelectedRide objectForKey:@"ArriveStart"] &&
 //      ![theSelectedRide objectForKey:@"LeaveStart"])[filterData setOn:NO];
    
    if(filterData.isOn){
        [self showFilteredRides];
      //  filterData.tintColor=[UIColor clearColor];
    }else if(![theSelectedRide objectForKey:@"ArriveStart"] &&
             ![theSelectedRide objectForKey:@"LeaveStart"]){
        [self showAllRides];
        filterData.tintColor=[UIColor colorWithRed:0.0 green:122/255. blue:1.0 alpha:1.0];
    }else{
        [self showAllRides];
        filterData.tintColor=[UIColor redColor];
        
    }
    
    if ([theSelectedRide objectForKey:@"GeoB"]) {
        myWork.coordinate=CLLocationCoordinate2DMake([[theSelectedRide objectForKey:@"GeoBlat"] doubleValue], [[theSelectedRide objectForKey:@"GeoB"] doubleValue]);
        [mapIt addAnnotation:myWork];
    }
    if ([theSelectedRide objectForKey:@"GeoA"]) {
        myHome.coordinate=CLLocationCoordinate2DMake([[theSelectedRide objectForKey:@"GeoAlat"] doubleValue], [[theSelectedRide objectForKey:@"GeoA"] doubleValue]);
        [mapIt addAnnotation:myHome];
    }
    
    edgeDistance=0; // this will assure a test for overlapping annotations
    [self mapView:mapIt regionDidChangeAnimated:YES];
        
}



-(void)showFilteredRides{

        
    if(![theSelectedRide objectForKey:@"ArriveStart"] &&
       ![theSelectedRide objectForKey:@"LeaveStart"] ){
        
        [filterData setOn:NO];
        [self matchRides:nil];
       UIAlertController* alert = [UIAlertController
                                   alertControllerWithTitle:@"Match Times Not Possible"
                                   message:@"\nYou need to\n\"Set times\" for this Ride\non the \"My Info\" page - \neither times to \"Arrive at 'Work':\"\nor times to \"Leave 'Work':\".  To do that, tap the \"My Info\" tab below.\n(Alternatively, just tap \"Do that now\" below.)"
                                   preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Do that now" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            
            self.tabBarController.selectedIndex=1;
            
        }];
        [alert addAction:defaultAction];
        UIAlertAction* defaultAction1 = [UIAlertAction actionWithTitle:@"Maybe later" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction1];
        [self presentViewController:alert animated:YES completion:nil];
    
        
    }
    
    for(int I=0;I<[[theSelectedRide objectForKey:@"Nearby50"] count];I++){
        NSDictionary *thisRide=[[theSelectedRide objectForKey:@"Nearby50"] objectAtIndex:I];
        BOOL rideMatches=NO;  // day and car
        
        NSDictionary *theSelection=thisRide;
        NSString *arriveStart=[theSelection objectForKey:@"ArriveStart"];
        NSString *arriveEnd=[theSelection objectForKey:@"ArriveEnd"];
        NSString *leaveStart=[theSelection objectForKey:@"LeaveStart"];
        NSString *leaveEnd=[theSelection objectForKey:@"LeaveEnd"];
        int yourDaysOfWeek= [[theSelection objectForKey:@"DaysOfTheWeek"] intValue];
        
        int myDaysOfTheWeek=[[theSelectedRide objectForKey:@"DaysOfTheWeek"] intValue];
        
        
        if([[self daysOverlapYours:yourDaysOfWeek mine:myDaysOfTheWeek] rangeOfString:@"✓"].length==1)rideMatches=YES;
        
  //      NSLog(@"the ride is %@    %i",[self daysOverlapYours:yourDaysOfWeek mine:myDaysOfTheWeek],rideMatches);
        
    
        
        int theirChoice=[[theSelection objectForKey:@"MyCarOrYours"] intValue];
        int myCarChoice=[[theSelectedRide objectForKey:@"MyCarOrYours"] intValue];
        if(theirChoice==0 && myCarChoice==0)rideMatches=NO;
        if(theirChoice==1 && myCarChoice==1)rideMatches=NO;
     //   NSLog(@"ride matches here1 %i",rideMatches);
        
        BOOL arrivalOverlaps=NO;
        BOOL leaveOverlaps=NO;
        if(arriveStart){
            if([theSelectedRide objectForKey:@"ArriveStart"]){
                
                int results=[self overLapIntervalsStart:[theSelectedRide objectForKey:@"ArriveStart"] End:[theSelectedRide objectForKey:@"ArriveEnd"] OtherStart:arriveStart OtherEnd:arriveEnd];
                arrivalOverlaps=YES;
                if(results>1000 || results==0) arrivalOverlaps=NO;
            }
        }
        if(leaveStart){
            if([theSelectedRide objectForKey:@"LeaveStart"]){
                
                int results=[self overLapIntervalsStart:[theSelectedRide objectForKey:@"LeaveStart"] End:[theSelectedRide objectForKey:@"LeaveEnd"] OtherStart:leaveStart OtherEnd:leaveEnd];
                leaveOverlaps=YES;
                if(results>1000 || results==0) leaveOverlaps=NO;
                
            }
        }
        
   //     NSLog(@"the rides match    %i  %i   %i",rideMatches,leaveOverlaps,arrivalOverlaps);
        
        MKPointAnnotation *anAnnotation=[[MKPointAnnotation alloc] init];
        anAnnotation.title=[NSString stringWithFormat:@"Home %i",(I+1)];
        anAnnotation.coordinate=CLLocationCoordinate2DMake([[thisRide objectForKey:@"GeoAlat"] doubleValue], [[thisRide objectForKey:@"GeoA"] doubleValue]);
        MKPointAnnotation *aWorkAnnotation=[[MKPointAnnotation alloc] init];
        aWorkAnnotation.title=[NSString stringWithFormat:@"Work %i",(I+1)];
        aWorkAnnotation.coordinate=CLLocationCoordinate2DMake([[thisRide objectForKey:@"GeoBlat"] doubleValue], [[thisRide objectForKey:@"GeoB"] doubleValue]);
        
        // include a full list of possible annotations so index matches up?
        [myAnnotations addObject:aWorkAnnotation];
        [myAnnotations addObject:anAnnotation];
        if(rideMatches && (leaveOverlaps || arrivalOverlaps)){  // it matches, place it on the map
            [mapIt addAnnotation:aWorkAnnotation];
            [mapIt addAnnotation:anAnnotation];
        }
    }
    
 //   NSLog(@"here showing filtered rides   %lu",(unsigned long)myAnnotations.count);
    tapMatchForInfo.hidden=(myAnnotations.count==0);
    
}



-(void)didTapMap:(id) sender{
    entriesInAGroup.hidden=YES;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    randomNumber=abs((int)[[[[UIDevice currentDevice] identifierForVendor] UUIDString] hash])%1000000;
    
    
    UITapGestureRecognizer* tapRec = [[UITapGestureRecognizer alloc]
                                      initWithTarget:self action:@selector(didTapMap:)];
    [mapIt addGestureRecognizer:tapRec];
    
    entriesInAGroup.dataSource=self;
    entriesInAGroup.delegate=self;
    
    dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"h:mm a"];
    
    requestFromAlert=NO;
    filterData.onTintColor=[UIColor colorWithRed:0 green:122/255. blue:1.0 alpha:1.0];
    float shift=([[UIScreen mainScreen] bounds].size.height-568)/2;
    if (shift<0)shift=0;
    containingView.frame=CGRectMake(([[UIScreen mainScreen] bounds].size.width-320)/2,shift, 320, 568);
    
    
    mapIt.pitchEnabled=NO;
    
    float longitudeValue=-74.66;  //default to princeton
    float latitudeValue=40.35;    //default to princeton
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latitudeValue,longitudeValue);
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coord, 1000, 1000);
    [mapIt setRegion:region animated:YES];
    mapIt.hidden=NO;
    mapIt.delegate=self;
    myHome=[[MKPointAnnotation alloc] init];
    myWork=[[MKPointAnnotation alloc] init];
    myHome.title=@"Home";
    myWork.title=@"Work";
    myAnnotations=[[NSMutableArray alloc] init];
    
    
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)showMap:(id)sender{
    entriesInAGroup.hidden=YES;
 //   NSLog(@"here and %@",[sender titleForState:UIControlStateNormal]);
    mapIt.hidden=NO;
    NSString *homeOrWork;
    double longitudeValue=-74.66;  //default to princeton
    double latitudeValue=40.35;    //default to princeton
    if([sender isEqual:locationA]){
   //     NSLog(@"show =home");
        if([theSelectedRide objectForKey:@"GeoA"]){
            longitudeValue=[[theSelectedRide objectForKey:@"GeoA"] doubleValue];
            if(![theSelectedAnnotation isEqualToString:@"Home"]){
           //     theHomeAnnotationView.enabled=YES;
                theHomeAnnotationView.canShowCallout=YES;
           //     theHomeAnnotationView.enabled=YES;
                theHomeAnnotationView.layer.zPosition=0;
                [mapIt selectAnnotation:myHome animated:YES];
                MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(myHome.coordinate,mapIt.region.span.latitudeDelta*1000/.009006, mapIt.region.span.longitudeDelta*1000/.014);
                [mapIt setRegion:region animated:YES];
                theHomeAnnotationView.canShowCallout=NO;
            //    theHomeAnnotationView.enabled=NO;
            }
        }
        if([theSelectedRide objectForKey:@"GeoAlat"])
            latitudeValue=[[theSelectedRide objectForKey:@"GeoAlat"] doubleValue];
    }else if([sender isEqual:locationB]){
    //    NSLog(@"show work");
        homeOrWork=@"GeoB";
        longitudeValue=-74.66;  //default to princeton
        latitudeValue=40.35;    //default to princeton
        if([theSelectedRide objectForKey:@"GeoB"]){
            longitudeValue=[[theSelectedRide objectForKey:homeOrWork] doubleValue];
            if(![theSelectedAnnotation isEqualToString:@"Work"]){
          //      theWorkAnnotationView.enabled=YES;
                theWorkAnnotationView.canShowCallout=YES;
           //     theWorkAnnotationView.enabled=YES;
                theWorkAnnotationView.layer.zPosition=0;
                [mapIt selectAnnotation:myWork animated:YES];
                MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(myWork.coordinate,mapIt.region.span.latitudeDelta*1000/.009006, mapIt.region.span.longitudeDelta*1000/.014);
                [mapIt setRegion:region animated:YES];
                theWorkAnnotationView.canShowCallout=NO;
            //    theWorkAnnotationView.enabled=NO;
            }
        }
        if([theSelectedRide objectForKey:@"GeoBlat"])
            latitudeValue=[[theSelectedRide objectForKey:@"GeoBlat"] doubleValue];
    }
    if(sender){
        
    //    NSLog(@"the sender is %@    %f   %f",sender,mapIt.region.span.latitudeDelta,mapIt.region.span.longitudeDelta);
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latitudeValue,longitudeValue);
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coord,mapIt.region.span.latitudeDelta*1000/.009006, mapIt.region.span.longitudeDelta*1000/.014);
        
        [mapIt setRegion:region animated:YES];
        
    }

}

@end
