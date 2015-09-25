//
//  MessageViewController.m
//  PrincetonRideShare
//
//  Created by Peter B Kramer on 6/7/15.
//  Copyright (c) 2015 Peter B Kramer. All rights reserved.
//

#import "MessageViewController.h"
#import "ChoicesViewController.h"

@interface MessageViewController (){
    
    NSMutableArray *myMessages;
    NSMutableDictionary *parameters;
    NSDateFormatter *dateFormat;
}

@end

@implementation MessageViewController



-(IBAction)infoButton:(id)sender{
    [self showChoicesWith:7];

}



-(void)getParameters:(NSMutableDictionary *)theParameters{
    parameters=theParameters;
}

-(IBAction)showMatch:(id)sender{
    [parameters setObject:[[theMessage.text substringFromIndex:9] substringToIndex:8] forKey:@"Show Match"];
    self.tabBarController.selectedIndex=2;
}




-(IBAction)cancelMessage:(id)sender{
    [theMessage resignFirstResponder];
    theMessage.hidden=YES;
    cancelMessage.hidden=YES;
    showMatch.hidden=YES;
    tapEntry.hidden=NO;
    deleteEntries.hidden=NO;
    infoButton.hidden=NO;
    theTable.frame=CGRectMake(20,60,280,330);
    
    if([[UIScreen mainScreen] bounds].size.height>480)theTable.frame=CGRectMake(20,60,280,450);
    
    [theTable reloadData];
    [theTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[myMessages count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    showKeyboard.hidden=YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    theTable.frame=CGRectMake(20,60,280,330);
    if([[UIScreen mainScreen] bounds].size.height>480)theTable.frame=CGRectMake(20,60,280,450);
    dateFormat=[[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MMM dd, h:mm a"];
  
    
    if(![parameters objectForKey:@"MyMessages"])
        [parameters setObject:[[NSMutableArray alloc] init] forKey:@"MyMessages"];
    myMessages=[parameters objectForKey:@"MyMessages"];
    if([myMessages count]==0)[myMessages addObject:@"No messages"];

    
 //test      [parameters removeObjectForKey:@"ReadAndAgreedTo"];
    
    
    
    if(![[parameters objectForKey:@"ReadAndAgreedTo"] boolValue]){
        tapEntry.hidden=YES;
        deleteEntries.hidden=YES;
        refreshMessages.hidden=YES;
        alertsLabel.hidden=YES;
        subscriptionsSwitch.hidden=YES;
        infoButton.hidden=NO;
        showKeyboard.hidden=NO;
    }
    
    [theTable setDelegate:self];
    [theTable setDataSource:self];
    [theMessage setDelegate:self];
    
    
    float shift=([[UIScreen mainScreen] bounds].size.height-568)/2;
    if (shift<0)shift=0;
    containingView.frame=CGRectMake(([[UIScreen mainScreen] bounds].size.width-320)/2,shift, 320, 568);
    
    
    // Do any additional setup after loading the view.
}


//  the button that reshows keyboard makes it the first responder and that's it

-(IBAction)showKeyboard:(id)sender{
    if([[sender titleForState:UIControlStateNormal] isEqualToString:@"Show Disclaimer"]){
        [self showChoicesWith:8];
    }else{
        [theMessage becomeFirstResponder];
    }
}

-(void)showChoicesWith:(int)selection{
    ChoicesViewController *choices = [[ChoicesViewController alloc] initWithNibName:@"ChoicesViewController" bundle:nil];
    [choices getParameters:parameters];
    [choices selectionIs:selection];
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:choices];
    navigationController.modalPresentationStyle=UIModalPresentationFormSheet;
    navigationController.navigationBar.tintColor=[UIColor colorWithRed:.9 green:.0 blue:0 alpha:1.0];
    
    [self presentViewController:navigationController animated:YES completion:nil];
    
}



-(IBAction)disclaimerSelector:(UISegmentedControl *)sender{
//    NSLog(@"here tttt");
    if(!sender || sender.selectedSegmentIndex==0){
        [self showChoicesWith:8];
    }else{
        [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"ReadAndAgreedTo"];
        [self viewWillAppearStuff];
    }
    
    
}

-(void)textViewDidBeginEditing:(UITextView *)textView{
    showKeyboard.hidden=YES;
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    
    if([text isEqualToString:@"\n"] && ![UIApplication sharedApplication].networkActivityIndicatorVisible){
        
        
        
        //disable the keyboard somehow
        
        
        
        
        //"Send to 123456-C:  blah blah blah    -
        //     so on the other end it is 'received from [my id number-mt ride number] 
        if(theMessage.text.length>8 && [[parameters objectForKey:@"iCloudRecordID"] intValue]!=0 && [theMessage.text containsString:@":"] && [theMessage.text containsString:@"-"]&& [theMessage.text containsString:@"From:"]&& [theMessage.text containsString:@"  \n"]   ){
            
            //also need to test the existance of a - after from:
            
            NSString *stringFromFrom=[theMessage.text substringFromIndex:[theMessage.text rangeOfString:@"From:"].location];
            int IDNumber=[[theMessage.text substringFromIndex:8] intValue];
            if(IDNumber>99999 && IDNumber<1000000 && [stringFromFrom containsString:@"-"] ){
                
             //   NSLog(@"here ffff0");
                
                    [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
                        if (accountStatus == CKAccountStatusNoAccount) {
                            [self iCloudErrorMessage:@"You must sign in to your iCloud account to send a message.\nOn the Home screen, launch the Settings App, tap \"iCloud\", and enter your Apple ID.  Then turn \"iCloud Drive\" on and allow this App to store data.\nIf you don't have an iCloud account, tap \"Create a new Apple ID\"." ];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [theMessage resignFirstResponder];
                                showKeyboard.hidden=NO;
                            });
                            
                        }else{
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                            CKContainer *defaultContainer=[CKContainer defaultContainer];
                            CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
                            CKRecord *aMessage=[[CKRecord alloc] initWithRecordType:@"Messages"];
                            
                            
                        //    NSLog(@"here ffff1");
                            
                            [aMessage setObject:[parameters objectForKey:@"iCloudRecordID"]  forKey:@"From"];
                            [aMessage setObject:[NSNumber numberWithInt:[[theMessage.text substringFromIndex:[theMessage.text rangeOfString:@":"].location+1] intValue]]  forKey:@"ToNumber"];
                         //   NSLog(@"here ffff");
                            [aMessage setObject:[[theMessage.text substringFromIndex:[theMessage.text rangeOfString:@"-"].location+1] substringToIndex:1] forKey:@"ToRide"];
                            [aMessage setObject:[[stringFromFrom substringFromIndex:
                                [stringFromFrom rangeOfString:@"-"].location+1] substringToIndex:1]forKey:@"FromRide"];
                            [aMessage setObject:[theMessage.text substringFromIndex:[theMessage.text rangeOfString:@"  \n"].location+3] forKey:@"Message"];
                            
                            [aMessage setObject:[NSNumber numberWithDouble: [NSDate timeIntervalSinceReferenceDate]]  forKey:@"DateD"];
                           
                            
                            
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
                                        [theMessage resignFirstResponder];
                                        showKeyboard.hidden=NO;
                                    });
                                    
                                    [self iCloudErrorMessage:errorMessage];
                                    
                                }else{
                                    //  change "Send to 123456-C..." to "To 123456-C
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                        
                                        NSDictionary *thisMessage=[[NSDictionary alloc] initWithObjectsAndKeys:[aMessage objectForKey:@"From"],@"From",[aMessage objectForKey:@"ToNumber"],@"ToNumber",[aMessage objectForKey:@"ToRide"],@"ToRide",[aMessage objectForKey:@"FromRide"],@"FromRide",[aMessage objectForKey:@"Message"],@"Message",[aMessage objectForKey:@"DateD"],@"DateD",[[NSMutableString alloc] initWithString:@"No"],@"Read",nil];
                                        [myMessages addObject:thisMessage];
                                        if([[myMessages objectAtIndex:0] isEqual:@"No messages"])[myMessages removeObjectAtIndex:0];
                                        [self cancelMessage:nil];
                                        [theMessage setText:@""];
                                    });
                                }
                            }];
                            
                         
                        }
                    }];
                
            }
            

            
                
            
        }   //    entered a \n,  could be icloud error here.  or else do this above?
 
        
    //    NSLog(@"here t");
        return NO;
        
    }else if(range.location<[theMessage.text rangeOfString:@"  \n"].location+3 ){//   theMessage.text.length-range.length<38){
        
        //theMessage.text=[theMessage.text substringToIndex:38];
     //   NSLog(@"here s");
        return NO;
    }else{
     //   NSLog(@"here r");
        return ![UIApplication sharedApplication].networkActivityIndicatorVisible;
        
    }
}

-(IBAction)getMessages:(id)sender{
    
    
    //  download any new messages, save them, clear the record and resave, then reload the table.
    
    
 //   NSLog(@"getting messages");
 //   [self cancelMessage:nil];
    
    if([[parameters objectForKey:@"iCloudRecordID"] intValue]!=0){
        [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
            if (accountStatus == CKAccountStatusNoAccount) {
              //  NSLog(@"error 11111");
                
             //   NSLog(@"zzz here mesaages");
                [self iCloudErrorMessage:@"You must sign in to your iCloud account to send or receive any messages.\nOn the Home screen, launch the Settings App, tap \"iCloud\", and enter your Apple ID. Then turn \"iCloud Drive\" on and allow this App to store data.\nIf you don't have an iCloud account, tap \"Create a new Apple ID\"." ];
            }else{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                CKContainer *defaultContainer=[CKContainer defaultContainer];
                CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
                
                
                
                
                NSPredicate *predicate=[NSPredicate predicateWithFormat:@"ToNumber == %i",[[parameters objectForKey:@"iCloudRecordID"] intValue] ];
                
                CKQuery *query=[[CKQuery alloc] initWithRecordType:@"Messages" predicate:predicate];
                query.sortDescriptors =[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"DateD" ascending:YES]];
                [publicDatabase performQuery:query inZoneWithID:nil completionHandler:
                 ^(NSArray *results, NSError *error){
                  //   NSLog(@"messages delibered the following number: %lu",(unsigned long)[results count]);
                     if(error){
                         if(error.code==CKErrorPartialFailure)error=nil;
                       //  NSLog(@"the error is %@",error);
                     }
                     if(error){
                         int seconds=0;
                         if(error.code==CKErrorServiceUnavailable || error.code==CKErrorRequestRateLimited)
                             seconds=[[[error userInfo] objectForKey:CKErrorRetryAfterKey] intValue];
                         if(seconds>0){
                             [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to get your messages.  Please try again after %i seconds.",seconds]];
                         }else{
                           //  NSLog(@"error is %ld   %@",(long)error.code,error);
                             
                             [self iCloudErrorMessage:@"There was an error trying to get your messages.  Please try again later."];
                         }
                         // return ;
                     }else{
                         if([results count]>0){  //    scanned for messages and got these.
                        //     NSLog(@"getting this result  %@",results);
                             NSMutableArray *theRecordIDs=[[NSMutableArray alloc] initWithCapacity:[results count]];
                             NSMutableArray *newMessages=[[NSMutableArray alloc] initWithCapacity:[results count]];
                             for (int I=0;I<[results count]; I++){
                                 CKRecord *aMessage=[results objectAtIndex:I];
                                 
                                 // check to see if aRecord has your ID on it, if so proceed to save an nsdictionary in messages and delete it in cloudkit.  otherwise, pass on the enxt porcedure.
                                 NSDictionary *aMessageToDownload=[NSDictionary dictionaryWithObjectsAndKeys:[aMessage objectForKey:@"ToNumber"] ,@"ToNumber",[aMessage objectForKey:@"ToRide"] ,@"ToRide",[aMessage objectForKey:@"FromRide"] ,@"FromRide",[aMessage objectForKey:@"From"] ,@"From",[aMessage objectForKey:@"Message"] ,@"Message",[aMessage objectForKey:@"DateD"] ,@"DateD",[[NSMutableString alloc] initWithString:@"Just downloaded"],@"Read", nil];
                           //      NSLog(@"the message is --- %@",aMessageToDownload);
                                 [newMessages addObject:aMessageToDownload];
                                 [theRecordIDs addObject:aMessage.recordID];
                             }
                             
                        //     NSLog(@"messages to delete  %@",theRecordIDs);
                             
                             CKModifyRecordsOperation *modifyRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:theRecordIDs];
                             modifyRecords.modifyRecordsCompletionBlock=^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
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
                                         [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to retrieve and then delete your retrieved messages from the server.  Please try again after %i seconds.",seconds]];
                                     }else{
                                      //   NSLog(@"the error was  %@",operationError);
                                         [self iCloudErrorMessage:@"There was an error trying to retrieve and then delete your retrieved messages from the server.  Please try again later."];
                                     }
                                 }else{
                                  //   NSLog(@"deleted these records:  %@",deletedRecordIDs);
                                     [myMessages addObjectsFromArray:newMessages];
                                     
                                     [self issueAlertResetBadge:[newMessages count]];
                                     
                                    
                                 }
                             };
                             [publicDatabase addOperation:modifyRecords];
                         }else{  // no messages for this device - no need to CKModifyBadgeOperation
                          //   NSLog(@"here 33333");
                             [self issueAlertResetBadge:0];
                             [self resetTheBadges];  // also sets the table to last entry...
                         }
                         
                     }
                 }];
                
                
                
                //background search for remaining from messages and reset the value if read
                NSPredicate *predicate1=[NSPredicate predicateWithFormat:@"From == %i",[[parameters objectForKey:@"iCloudRecordID"] intValue] ];
                
                CKQuery *query1=[[CKQuery alloc] initWithRecordType:@"Messages" predicate:predicate1];
                [publicDatabase performQuery:query1 inZoneWithID:nil completionHandler:
                 ^(NSArray *results, NSError *error){
                     
             //        NSLog(@"here 45372");
                     if(error){
                         if(error.code==CKErrorPartialFailure)error=nil;
                     }
                     if(error){
                         dispatch_async(dispatch_get_main_queue(), ^{
                         });
                     }else{
                         NSMutableArray *myFromDates=[[NSMutableArray alloc] initWithCapacity:[results count]];
                         for(int I=0;I<[results count];I++){
                             if(
                                //   in the predicate.....[[[results objectAtIndex:I ] objectForKey:@"From"] isEqualToNumber:[parameters objectForKey:@"iCloudRecordID"]] &&// from this device
                                [[results objectAtIndex:I] objectForKey:@"DateD"]){
                                 [myFromDates addObject:[[results objectAtIndex:I] objectForKey:@"DateD"]];
                             }
                         }
                     //    NSLog(@"the dates are %@",myFromDates);
                         for(int I=0;I<[myMessages count];I++){  // mark the message as 'read'
                           //  NSLog(@"the message is   %@",[myMessages objectAtIndex:I] );
                             if([[myMessages objectAtIndex:I] isKindOfClass:[NSDictionary class]]){
                               //  NSLog(@"doing comarison   %@  %@",[[myMessages objectAtIndex:I] objectForKey:@"DateD"],[[myMessages objectAtIndex:I] objectForKey:@"Read"]);
                                 if(![[[myMessages objectAtIndex:I] objectForKey:@"Read"] isEqualToString:@"Yes"] && ![[[myMessages objectAtIndex:I] objectForKey:@"Read"] isEqualToString:@"Just downloaded"] )
                                     if(![myFromDates containsObject: [[myMessages objectAtIndex:I] objectForKey:@"DateD"]] ){
                                    //     NSLog(@"changing to yes---%@-",[[myMessages objectAtIndex:I] objectForKey:@"Read"]);
                                         [[[myMessages objectAtIndex:I] objectForKey:@"Read"] setString:@"Yes"];
                                     }
                             }
                         }
                         
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [theTable reloadData];
                            });
                     }
                 }];
                
                
                
            }
        }];
    }
}

-(void)issueAlertResetBadge:(long)newMessageCount{
    CKContainer *defaultContainer=[CKContainer defaultContainer];
    
    NSMutableArray *array = [NSMutableArray array];
    NSMutableArray *arrayOthers = [NSMutableArray array];
    __block NSString *message=@"";
    CKFetchNotificationChangesOperation *operation = [[CKFetchNotificationChangesOperation alloc] initWithPreviousServerChangeToken:nil];
    operation.notificationChangedBlock = ^(CKNotification *notification) {
        
        if(notification.notificationType==1){
            if([notification.alertLocalizationArgs count]>0){
                if([[notification.alertLocalizationArgs objectAtIndex:1] intValue] == [[parameters objectForKey:@"iCloudRecordID"] intValue]){
                    [array addObject:notification.notificationID];
                }else{
                    [arrayOthers addObject:notification.notificationID];
                    if(![[parameters objectForKey:@"Previous Notifications"] containsObject:notification.notificationID]){
                        message=[message stringByAppendingFormat:@"\nDevice %@",[[notification alertLocalizationArgs] objectAtIndex:1]];
                    }
                }
            }
        }
     //   NSLog(@"Got a notification   %@",notification);
    };
    operation.completionBlock = ^(){
        CKMarkNotificationsReadOperation *op = [[CKMarkNotificationsReadOperation alloc] initWithNotificationIDsToMarkRead:array];
        op.markNotificationsReadCompletionBlock=^(NSArray *iDsRead, NSError *operationError){
          //  NSLog(@"here is what we did....%@   and the error was -%@-",iDsRead,operationError);
            long numberOfRemainingNotifications=[arrayOthers count];
            // issue alerts here based on
            //     1) newMessages count ==0 or not
            //     2) objects in arrayOthers not being in parameters objectfor key Not New Notifications
            //  then reset not new notifications to arrayOthers
            
            NSString *title;
            
       //     NSLog(@"the two arrays are \n%@     and   \n%@",arrayOthers,[parameters objectForKey:@"Previous Notifications"]);
            [parameters setObject:arrayOthers forKey:@"Previous Notifications"];
            if(newMessageCount>0 && ![message isEqualToString:@""]){
                title=@"Messages For Other Devices";
                message =[@"You have other devices logged into the same iCloud Account.  In addition to new messages for this device, there are new messages for:\n" stringByAppendingString:message];
            }else if(![message isEqualToString:@""]){
                title=@"Messages For Other Devices";
                message =[@"You have other devices logged into the same iCloud Account.  There are no new messages for this device but there are new messages for:\n" stringByAppendingString:message];
            }else if(newMessageCount==0 && [[self tabBarItem] badgeValue]>0){   // only if there is a badge....
                title=@"No New Messages";
                message =@"You have other devices logged into the same iCloud Account.  There are no new messages for this device and your other devices have retrieved their new messages.";
            }
            if(title){
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                    [alert addAction:defaultAction];
                    [self presentViewController:alert animated:YES completion:nil];
                });
            }
            CKModifyBadgeOperation *resetBadge=[[CKModifyBadgeOperation alloc] initWithBadgeValue:numberOfRemainingNotifications];
          //  NSLog(@"reset badge to %li",numberOfRemainingNotifications);
            resetBadge.modifyBadgeCompletionBlock=^(NSError *error){
                if (error) {
          //          NSLog(@"Error resetting badge: %@",error);
                }else {
            //        NSLog(@"reset badge to %li  confirmed",numberOfRemainingNotifications);
                }
                [self resetTheBadges];
            };
            [defaultContainer addOperation:resetBadge];
        } ;
        //  [op start];
        [defaultContainer addOperation:op];
   //     NSLog(@"marked them as read");
    };
    [defaultContainer addOperation:operation];
    //                                     [operation start];
    
    
}



-(void)resetTheBadges{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [theTable reloadData];
        [theTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[myMessages count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        
        
        [[self tabBarItem] setBadgeValue:nil];
        
        
        //??????
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        
        
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
  //      NSLog(@"here 777");
    });
}

-(void)viewWillAppearStuff{  // can be called by app delegate
    
    for(int I=0;I<[myMessages count];I++){  // mark the message as 'read' if 'Just downloaded'
        if([[myMessages objectAtIndex:I] isKindOfClass:[NSDictionary class]]){
            if([[[myMessages objectAtIndex:I] objectForKey:@"Read"] isEqualToString:@"Just downloaded"])
                [[[myMessages objectAtIndex:I] objectForKey:@"Read"] setString:@"Yes"];
        }
    }
    
    
    //   moved stuff to end from here
    
    //  [theMessage becomeFirstResponder];
    [theTable setDelegate:self];
    [theTable setDataSource:self];
    [theMessage setDelegate:self];
    
    
    float shift=([[UIScreen mainScreen] bounds].size.height-568)/2;
    if (shift<0)shift=0;
    containingView.frame=CGRectMake(([[UIScreen mainScreen] bounds].size.width-320)/2,shift, 320, 568);
    
    
    
    //   NSUserDefaults *localDefaults=[NSUserDefaults standardUserDefaults];
    if([parameters objectForKey:@"Match ID"] && [[parameters objectForKey:@"ReadAndAgreedTo"] boolValue]){
        theMessage.hidden=NO;
        [theMessage becomeFirstResponder];
        cancelMessage.hidden=NO;
        showMatch.hidden=NO;
        tapEntry.hidden=YES;
        deleteEntries.hidden=YES;
        infoButton.hidden=YES;
        theMessage.text=[NSString stringWithFormat:@"Send to: %@         From: %i-%@\n              Date: %@  \nWe Match.  If you are interested in Ride Sharing please respond to his message.",[parameters objectForKey:@"Match ID"],[[parameters objectForKey:@"iCloudRecordID"] intValue],[[@"ABCDE" substringFromIndex:[[parameters objectForKey:@"RideSelected"]  intValue] ] substringToIndex:1],[dateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]] ];
        
        [parameters removeObjectForKey:@"Match ID"];
        
        theTable.frame=CGRectMake(20,60,280,80);
        
        
        
        [theTable reloadData];
        [theTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[myMessages count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        
    }else if ([[parameters objectForKey:@"ReadAndAgreedTo"] boolValue] && showMatch.hidden){
  
        [self getMessages:nil];
        
        [theTable reloadData];
        [theTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[myMessages count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        
    }else if ([[parameters objectForKey:@"ReadAndAgreedTo"] boolValue] ){//showMatch is not hidden
        [theMessage becomeFirstResponder];
    }
    
    
    if([[parameters objectForKey:@"ReadAndAgreedTo"] boolValue] &&
       [[showKeyboard titleForState:UIControlStateNormal] isEqualToString:@"Show Disclaimer"]){
        
        // when first agreed to and when first loaded (if agreed to)
        
        disclaimerLabel.hidden=YES;
        tapEntry.hidden=NO;
        deleteEntries.hidden=[[myMessages objectAtIndex:0] isEqual:@"No messages"];
        refreshMessages.hidden=NO;
        alertsLabel.hidden=NO;
        subscriptionsSwitch.hidden=NO;
        infoButton.hidden=NO;
        showKeyboard.hidden=YES;
        [showKeyboard setTitle:@"Show keyboard" forState:UIControlStateNormal];
        [self subscriptionSwitch:nil];
    }
    
    
    
    
    
    
 //   NSLog(@"viewwillappear meassages");
    
    
}



-(void)viewWillAppear:(BOOL)animated{
    
 //   NSLog(@"messages viewwillappear");
    [super viewWillAppear:animated];
 
    
    [self viewWillAppearStuff];
}

-(void)iCloudErrorMessage:(NSString *)message{
    
    dispatch_async(dispatch_get_main_queue(), ^{
   //     NSLog(@"Issue an error message");
        if(self.presentedViewController){
      //      NSLog(@"Issue a delay");
            [self performSelector:@selector(iCloudErrorMessage:) withObject:message afterDelay:0.4f];
        }else{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"iCloud Error" message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Sorry" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)subscriptionSwitch:(id)sender{
  //  NSLog(@"testing subscription");
    
    //   if sender is nil, its first time or disclaimer just signed.
    //     there may be a request for alerts out there.
    // test for icloud available, if not -
    //  need to issue an error if sender is not nil and switch is set to on
    //   and set the switch to off.
    //   need to issue an error if sender is not nil and switch is off,
    
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    CKContainer *defaultContainer=[CKContainer defaultContainer];
    CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
    [publicDatabase fetchAllSubscriptionsWithCompletionHandler:^(NSArray *subscriptions, NSError *error) {
        if (error) {
          //  NSLog(@"Error in deleteAllSubscriptions: %@", error);
            
            // if this is from a load or user just ReadAndAgreed then don't issue error message (sender=nil)
            
            if(sender)
                [self iCloudErrorMessage:@"Unable to set up Message alerts.  Please try again later."];
            dispatch_async(dispatch_get_main_queue(), ^{
                [subscriptionsSwitch setOn:NO animated:YES];
         //       refreshMessages.hidden=subscriptionsSwitch.isOn;
             });
        } else {
            NSMutableArray *currentSubscriptions=[[NSMutableArray alloc] initWithCapacity:[subscriptions count]];
        //    NSLog(@"THE SUBSCRIPTION COUNT IS %lu",(unsigned long)[subscriptions count]);
            NSString *subscriptionIDToAdd=[NSString stringWithFormat:@"%i",[[parameters objectForKey:@"iCloudRecordID"] intValue]] ;
            for (CKSubscription *subscription in subscriptions) {
                    [currentSubscriptions addObject:subscription.subscriptionID];
            }
            
        //    NSLog(@"the arrays are %@    and %@",currentSubscriptions,subscriptionIDToAdd);
            BOOL goalIsSubscribe=subscriptionsSwitch.isOn;
        
            if(!sender && [currentSubscriptions containsObject:subscriptionIDToAdd]){
                //called from get parameters and subscription is showing iCloud.
                //  need to set switch and register notifications on this device 'at launch'.
                //   other devices owned by this user may have turned on subscription
                goalIsSubscribe=YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [subscriptionsSwitch setOn:YES];
          //          refreshMessages.hidden=subscriptionsSwitch.isOn;
                });
            }
            
            
            // register for notifications and issue an alert if necessary
            if(goalIsSubscribe){
           //     NSLog(@"asking about notifications");
                
                UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeBadge | UIUserNotificationTypeAlert;
                UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
                [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
                [[UIApplication sharedApplication] registerForRemoteNotifications];
         
            
            }
            NSArray *subscriptionToAdd;
            if(goalIsSubscribe && ![currentSubscriptions containsObject:subscriptionIDToAdd]){
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
            
            NSArray *subscriptionToDelete;
            if(!goalIsSubscribe && [currentSubscriptions containsObject:subscriptionIDToAdd] ){
                subscriptionToDelete=[NSArray arrayWithObject:subscriptionIDToAdd];
            }else{
                subscriptionToDelete=nil;
            }
            
            
            if([subscriptionToDelete count]+[subscriptionToAdd count]>0){
                //   need to do something, delete perhaps, add perhaps
                
                CKModifySubscriptionsOperation *modifySubscriptions=[[CKModifySubscriptionsOperation alloc] initWithSubscriptionsToSave:subscriptionToAdd subscriptionIDsToDelete:subscriptionToDelete]; // want to delete previous users of this device
         //       NSLog(@"the arguments are %@   %@",subscriptionToAdd,subscriptionToDelete);
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
                            [self iCloudErrorMessage:[NSString stringWithFormat:@"There was an iCloud resource issue trying to change your Message alerts.  Please try again after %i seconds.",seconds]];
                        }else{
                         //   NSLog(@"the error was  %@",operationError);
                            [self iCloudErrorMessage:@"There was an error trying to change your Message alerts.  Please try again later."];
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [subscriptionsSwitch setOn:NO animated:YES];
                    //        refreshMessages.hidden=subscriptionsSwitch.isOn;
                        });
                    }else{
                     //   NSLog(@"Subscribed succesfully - saved this subscription:  %@",savedSubscriptions);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        });
                    }
                };
           //     NSLog(@"and here is the subscription just before delete/add operation %@ -  %@",subscriptionNames,itemSubscription);
                [publicDatabase addOperation:modifySubscriptions];
            }else{
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                });
                
                
            }
            
        }
    }];
}

-(IBAction)deleteEntries:(id)sender{
    if([[deleteEntries titleForState:UIControlStateNormal] isEqualToString:@"Delete Entries"]){
        [theTable setEditing:YES animated:YES];
        [deleteEntries setTitle:@"Done" forState:UIControlStateNormal];
    }else{
        [theTable setEditing:NO animated:YES];
        [deleteEntries setTitle:@"Delete Entries" forState:UIControlStateNormal];
    }
    [theTable reloadData];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if([[myMessages objectAtIndex:0] isEqual:@"No messages"]){
        return NO;
    }
    return YES;
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return UITableViewCellEditingStyleDelete;
   
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
  //  NSLog(@"here ss-1");
    NSNumber *theDateToDelete;
    if([[myMessages objectAtIndex:[indexPath row]] isKindOfClass:[NSDictionary class]])
        theDateToDelete =[[[myMessages objectAtIndex:[indexPath row]] objectForKey:@"DateD"] copy];
    [myMessages removeObjectAtIndex:[indexPath row]];
    if([myMessages count]==0){
        [myMessages addObject:@"No messages"];
        [theTable setEditing:NO animated:YES];
        [deleteEntries setTitle:@"Delete Entries" forState:UIControlStateNormal];
        [tableView reloadData];
     //   NSLog(@"here 222222");
    }else{
        
        
        
     //   NSLog(@"here ss0");
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        
        CKContainer *defaultContainer=[CKContainer defaultContainer];
        CKDatabase *publicDatabase=[defaultContainer publicCloudDatabase];
        NSPredicate *predicate1=[NSPredicate predicateWithFormat:@"From == %i",[[parameters objectForKey:@"iCloudRecordID"] intValue] ];
        
        CKQuery *query1=[[CKQuery alloc] initWithRecordType:@"Messages" predicate:predicate1];
        [publicDatabase performQuery:query1 inZoneWithID:nil completionHandler:
         ^(NSArray *results, NSError *error){
             if(error){
                // NSLog(@"error 4444");
             }else{
               //  NSLog(@"here ss");
                 for(int I=0;I<[results count];I++){
                   //  NSLog(@"here ss1");
                     
                     if([[results objectAtIndex:I ] isKindOfClass:[NSDictionary class]]){
                       //  NSLog(@"here ss2");
                         if(
                           //   this is in the predicate....... [[[results objectAtIndex:I ] objectForKey:@"From"] isEqualToNumber:[parameters objectForKey:@"iCloudRecordID"]] &&// from this device
                            [[results objectAtIndex:I] objectForKey:@"DateD"]){
                             
                             if([[[results objectAtIndex:I] objectForKey:@"DateD"] isEqualToNumber:theDateToDelete]){
                                 
                                 
                                 CKModifyRecordsOperation *modifyRecords= [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:[NSArray arrayWithObject:[[results objectAtIndex:I] recordID]]];
                                 modifyRecords.modifyRecordsCompletionBlock=^(NSArray * savedRecords, NSArray * deletedRecordIDs, NSError * operationError){
                                     if(operationError){
                                   //      NSLog(@"error 222   %@",operationError);
                                     }
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                     });
                                 };
                                 [publicDatabase addOperation:modifyRecords];
                             }
                         }
                     }
                     
                     
                     
                 }
             }
             dispatch_async(dispatch_get_main_queue(), ^{
                     [theTable reloadData];
                 });
             
         }];
    }
    
  //  NSLog(@"here ss8");
}




- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if([[myMessages objectAtIndex:0] isEqual:@"No messages"]){
        tapEntry.text=@"You can only send\nmessages to a match";
        deleteEntries.hidden=YES;
    }else{
        tapEntry.text=@"Tap entry to respond\n";
        deleteEntries.hidden=tapEntry.hidden;
    //    infoButton.hidden=tapEntry.hidden;
    }
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [myMessages count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 100;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *textCellIndentifier=@"TextCell";
    
    UITableViewCell *cell;
    cell=[tableView dequeueReusableCellWithIdentifier:textCellIndentifier];
    if(cell==nil)cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:textCellIndentifier];
    cell.textLabel.numberOfLines=8;
    cell.textLabel.font=[UIFont systemFontOfSize:13];
//    cell.imageView.image=[UIImage imageNamed:@"twitter2.png"];
    
    if([[deleteEntries titleForState:UIControlStateNormal] isEqualToString:@"Done"])
        cell.textLabel.font=[UIFont systemFontOfSize:11];
    
    
    //
    if([[myMessages objectAtIndex:[indexPath row]] isKindOfClass:[NSDictionary class]]  ){
        NSDictionary *aMessage=[myMessages objectAtIndex:[indexPath row]];
        NSString *theFormatedDate;
        if([[aMessage objectForKey:@"DateD"]  isKindOfClass:[NSDate class]]){
            theFormatedDate=[dateFormat stringFromDate:[aMessage objectForKey:@"DateD"]];
        }else{
            theFormatedDate=[dateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:[[aMessage objectForKey:@"DateD"] doubleValue]]];
        }
        
        cell.textLabel.textColor=[UIColor blackColor];
        
        if([[aMessage objectForKey:@"ToNumber"] isEqualToNumber:[parameters objectForKey:@"iCloudRecordID"]]){
            cell.textLabel.text=[NSString stringWithFormat:@"From: %i-%@        To:     %i-%@\n             Date: %@  \n%@",[[aMessage objectForKey:@"From"] intValue],[aMessage objectForKey:@"FromRide"],[[aMessage objectForKey:@"ToNumber"] intValue],[aMessage objectForKey:@"ToRide"],theFormatedDate,[aMessage objectForKey:@"Message"]];
            if([aMessage objectForKey:@"Read"])
                if([[aMessage objectForKey:@"Read"] isEqualToString:@"Just downloaded"])
                    cell.textLabel.textColor=[UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0];
                
                
            
        }else{  // I sent this message to someone
            if([aMessage objectForKey:@"Read"]){
                
             //   NSLog(@"the read value is set   -%@-",[aMessage objectForKey:@"Read"]);
                if([[aMessage objectForKey:@"Read"] isEqualToString:@"No"])
                    cell.textLabel.textColor=[UIColor colorWithRed:0.0 green:122/255. blue:1.0 alpha:1.0];
            }
         //   NSLog(@"a message is %@",aMessage);
            cell.textLabel.text=[NSString stringWithFormat:@"To:     %i-%@        From: %i-%@\n             Date: %@  \n%@",[[aMessage objectForKey:@"ToNumber"] intValue],[aMessage objectForKey:@"ToRide"],[[aMessage objectForKey:@"From"] intValue],[aMessage objectForKey:@"FromRide"],theFormatedDate,[aMessage objectForKey:@"Message"]];
            
        }
    }else{
      //  NSLog(@"doing this with this %@",[myMessages objectAtIndex:[indexPath row]]);
        cell.textLabel.text=[myMessages objectAtIndex:[indexPath row]];
        if([[cell.textLabel.text substringToIndex:2] isEqualToString:@"To"])
            cell.textLabel.text=[@"    " stringByAppendingString:cell.textLabel.text];
    }
    
    
    // This is how you change the background color
   //     cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = [UIColor colorWithRed:220/255. green:255/255. blue:1.0 alpha:1.0];
        [cell setSelectedBackgroundView:bgColorView];
    
    
    
    return cell;
}


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if([[myMessages objectAtIndex:[indexPath row]] isKindOfClass:[NSDictionary class]]  ){
        NSString *postThisMessage;
        NSDictionary *aMessage=[myMessages objectAtIndex:[indexPath row]];
        if([[aMessage objectForKey:@"ToNumber"] isEqualToNumber:[parameters objectForKey:@"iCloudRecordID"]]){ // this message was sent to me, i am responding
            postThisMessage=[NSString stringWithFormat:@"Send to: %i-%@         From: %i-%@\n              Date: %@  \n",[[aMessage objectForKey:@"From"] intValue],[aMessage objectForKey:@"FromRide"],[[aMessage objectForKey:@"ToNumber"] intValue],[aMessage objectForKey:@"ToRide"],[dateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0] ]];
        }else{  // i am responding to a message I sent, this is another message to same person
            postThisMessage=[NSString stringWithFormat:@"Send to: %i-%@         From: %i-%@\n              Date: %@  \n",[[aMessage objectForKey:@"ToNumber"] intValue],[aMessage objectForKey:@"ToRide"],[[aMessage objectForKey:@"From"] intValue],[aMessage objectForKey:@"FromRide"],[dateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]]];
        }
        theMessage.text=postThisMessage;
        theMessage.hidden=NO;
        [theMessage becomeFirstResponder];
        cancelMessage.hidden=NO;
        showMatch.hidden=NO;
        tapEntry.hidden=YES;
        deleteEntries.hidden=YES;
     
        infoButton.hidden=YES;
        
        
        tableView.frame=CGRectMake(20,60,280,80);
        [theTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }else{
        
        NSString *postedMessage=[myMessages objectAtIndex:[indexPath row]];
        if ([[myMessages objectAtIndex:[indexPath row]] isEqual:@"No messages"] || postedMessage.length<6) {
            [tableView reloadData];
        }else{
            if([[postedMessage substringToIndex:3] isEqual:@"To "]){
                postedMessage=[postedMessage substringFromIndex:3];  // remove "To " if there
            }else if([[postedMessage substringToIndex:5] isEqual:@"From "]){
                postedMessage=[postedMessage substringFromIndex:5];  // remove "From " if there
            }else{
                [tableView reloadData];
                return;
            }  //   "123456-C regarding my Ride B:  blah blah blah"
            if(postedMessage.length>=30){
                theMessage.text=[NSString stringWithFormat:@"Send to %@",[postedMessage substringToIndex:30]];
                theMessage.hidden=NO;
                [theMessage becomeFirstResponder];
                cancelMessage.hidden=NO;
                showMatch.hidden=NO;
                tapEntry.hidden=YES;
                deleteEntries.hidden=YES;
                infoButton.hidden=YES;
                tableView.frame=CGRectMake(20,60,280,80);
                [theTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }else{
            }
        }
    }
}


@end
