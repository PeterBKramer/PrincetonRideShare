//
//  MessageViewController.m
//  PrincetonRideShare
//
//  Created by Peter B Kramer on 6/7/15.
//  Copyright (c) 2015 Peter B Kramer. All rights reserved.
//

#import "MessageViewController.h"
#import "ChoicesViewController.h"
//#import "messageViewer.h"

@interface MessageViewController (){
    
    NSMutableArray *myMessagePackets;
    NSMutableArray *myMessages;
    NSMutableDictionary *parameters;
    NSDateFormatter *dateFormat;
    BOOL groupTheMessages;
    NSNumber *theRecordID;
    BOOL requestGetMessage;
    NSDate *now;
    NSDateFormatter *fullDateFormat;
    long rowToDelete;
    NSString *status;
}

@end

@implementation MessageViewController



-(IBAction)infoButton:(id)sender{
    [self showChoicesWith:7];

}



-(void)getParameters:(NSMutableDictionary *)theParameters{
    parameters=theParameters;
    myMessagePackets=[[NSMutableArray alloc] init];
    groupTheMessages=YES;
    myMessages=[parameters objectForKey:@"MyMessages"];
    if([myMessages count]==0)[myMessages addObject:@"No messages"];//this shouldn't be necessary
    [self constructMyMessagePackets];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(returnFromCloud:)
                                                 name:@"ReturnFromCloud" object:nil];
}

-(IBAction)showMatch:(id)sender{
    
    
    int toNumber=[[theMessage.text substringFromIndex:[theMessage.text rangeOfString:@":"].location+1] intValue];
    NSString *toRideLetter=[[theMessage.text substringFromIndex:[theMessage.text rangeOfString:@"-"].location+1] substringToIndex:1];
    [parameters setObject:[NSString stringWithFormat:@"%i-%@",toNumber,toRideLetter] forKey:@"Show Match"];
    
    NSString *fromText=[theMessage.text substringFromIndex:[theMessage.text rangeOfString:@"From:"].location];
    NSString *rideLetter=[[fromText substringFromIndex:[fromText rangeOfString:@"-"].location+1] substringToIndex:1];
    long rideNumber=[@"ABCDE" rangeOfString:rideLetter].location;
    
    [parameters setObject:[NSNumber numberWithLong:rideNumber] forKey:@"RideSelected"];
     
    self.tabBarController.selectedIndex=2;
}

-(IBAction)sendButton:(id)sender{
    
    if(![UIApplication sharedApplication].networkActivityIndicatorVisible){
        
        
        
        //disable the keyboard somehow
        
        
        
        
        //"Send to 123456-C:  blah blah blah    -
        //     so on the other end it is 'received from [my id number-mt ride number]
        if(theMessage.text.length>8 && [[parameters objectForKey:@"iCloudRecordID"] intValue]!=0 && [theMessage.text containsString:@":"] && [theMessage.text containsString:@"-"]&& [theMessage.text containsString:@"From:"]&& [theMessage.text containsString:@"  \n"]   ){
            
            //also need to test the existance of a - after from:
            
            NSString *stringFromFrom=[theMessage.text substringFromIndex:[theMessage.text rangeOfString:@"From:"].location];
            long locationOfColon=[theMessage.text rangeOfString:@":"].location+1;
            if(locationOfColon>9)locationOfColon=0;
            int IDNumber=[[theMessage.text substringFromIndex:locationOfColon] intValue];
            if(locationOfColon!=0 && IDNumber>99999 && IDNumber<10000000 && [stringFromFrom containsString:@"-"] ){
                
                //   NSLog(@"here ffff0");
                
                
                
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MessagesProcedures" object:theMessage.text];
                
                [self cancelMessage:@"GoingToiCloud"];
            
            }
            
            
            
            
            
        }   //    entered a \n,  could be icloud error here.  or else do this above?
        
        
        //    NSLog(@"here t");
        
        
        
    }
}


-(void)constructMyMessagePackets{
 //   NSLog(@"the packets were %@",myMessagePackets);
    [myMessagePackets removeAllObjects];
    
 // can no longer happen:
    if ([myMessages count]==0)
        [myMessages addObject:@"No messages"];
    
    if([[myMessages objectAtIndex:0] isKindOfClass:[NSString class]]){
        [myMessagePackets addObject:@"No messages"];
        return;
    }
    
            
    NSMutableArray *messagePacketIDs=[[NSMutableArray alloc] init];
    for(long I=[myMessages count]-1;I>=0;I--){
        
        NSDictionary *aMessage=[myMessages objectAtIndex:I];
        NSNumber *newIDNumber=[aMessage objectForKey:@"ToNumber"];
        if([[aMessage objectForKey:@"ToNumber"] isEqualToNumber:[parameters objectForKey:@"iCloudRecordID"]])newIDNumber=[aMessage objectForKey:@"From"];
        
        if(!groupTheMessages && [newIDNumber isEqualToNumber:theRecordID]){
            [myMessagePackets insertObject:aMessage atIndex:0];  //    add at top not bottom
        }else if(groupTheMessages && ![messagePacketIDs containsObject:newIDNumber]){
            [messagePacketIDs addObject:newIDNumber];
            [myMessagePackets insertObject:aMessage atIndex:0];  //    add at top not bottom
        }
    }
    
    if([myMessagePackets count]==0)
        [myMessagePackets addObject:@"No messages"];
}




-(IBAction)cancelMessage:(id)sender{
   /*
    if(![sender isEqual:@"ReturnFromiCloud"]){
        [theMessage resignFirstResponder];
        theMessage.hidden=YES;
        cancelMessage.hidden=YES;
        showMatch.hidden=YES;
        buttonBackground.hidden=YES;
        sendButton.hidden=YES;
        showKeyboard.hidden=YES;
    }
    
    if(![sender isEqual:@"GoingToiCloud"]){  // not done immediately
        [parameters removeObjectForKey:@"Match ID"];
        if(requestGetMessage)[self getMessages:nil];
        
        infoButton.hidden=NO;
        tapEntry.hidden=NO;
        alertsLabel.hidden=NO;
        refreshMessages.hidden=NO;
        subscriptionsSwitch.hidden=NO;
        deleteEntries.hidden=NO;
        
    }
    */
    if([sender isEqual:@"GoingToiCloud"]){
        status=@"Sending";
 //   }else if ([sender isEqual:@"ReturnFromiCloud"]){
   //     status=@"Regular";
    }else{
        status=@"Regular"; //   from the cancel button
    }
    
    [self redoTheScreen];
    [theTable reloadData];
    [theTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[myMessagePackets count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
    
}

-(void)redoTheScreen{
    
  //  NSLog(@"the status is ........%@",status);
    [self constructMyMessagePackets];
   
    
    if([status isEqualToString:@"Sending"]){
        [theMessage resignFirstResponder];
        theMessage.hidden=YES;
        cancelMessage.hidden=YES;
        showMatch.hidden=YES;
        buttonBackground.hidden=YES;
        sendButton.hidden=YES;
        showKeyboard.hidden=YES;
    }else if([status isEqualToString:@"Regular"]){
        [theMessage resignFirstResponder];
        theMessage.hidden=YES;
        cancelMessage.hidden=YES;
        showMatch.hidden=YES;
        buttonBackground.hidden=YES;
        sendButton.hidden=YES;
        showKeyboard.hidden=YES;
        [parameters removeObjectForKey:@"Match ID"];
        if(requestGetMessage)[self getMessages:nil];
        infoButton.hidden=NO;
        tapEntry.hidden=NO;
        alertsLabel.hidden=NO;
        refreshMessages.hidden=NO;
        subscriptionsSwitch.hidden=NO;
        deleteEntries.hidden=NO;
    }else if([status isEqualToString:@"Compose"]){
        theMessage.hidden=NO;//
        [theMessage becomeFirstResponder];
        cancelMessage.hidden=NO;//
        showMatch.hidden=NO;//
        buttonBackground.hidden=NO;//
        sendButton.hidden=NO;//
        tapEntry.hidden=YES;
        deleteEntries.hidden=YES;
        infoButton.hidden=YES;
        alertsLabel.hidden=YES;
        refreshMessages.hidden=YES;
        messagesFromTo.hidden=YES;
        messagesToFromBackground.hidden=YES;
        closeButton.hidden=YES;
        subscriptionsSwitch.hidden=YES;
    }else if ([status isEqualToString:@"DoNothing"]){
        
    }else if ([status isEqualToString:@"FirstTime"]){
        if(theMessage.hidden){   //   don't do these if sending a message
            tapEntry.hidden=NO;
            refreshMessages.hidden=NO;
            alertsLabel.hidden=NO;
            subscriptionsSwitch.hidden=NO;
            infoButton.hidden=NO;
        }
        deleteEntries.hidden=[[myMessagePackets objectAtIndex:0] isEqual:@"No messages"];
        disclaimerLabel.hidden=YES;
        showKeyboard.hidden=YES;
        [showKeyboard setTitle:@"Show keyboard" forState:UIControlStateNormal];
    }else if ([status isEqualToString:@"Compose1"]){
        showKeyboard.hidden=NO;
        theMessage.hidden=NO;
        cancelMessage.hidden=NO;
        showMatch.hidden=NO;
        buttonBackground.hidden=NO;
        sendButton.hidden=NO;
    }else if ([status isEqualToString:@"Delete"]){
        tapEntry.hidden=YES;
        closeButton.hidden=YES;
    }else if ([status isEqualToString:@"EndDelete"]){
        tapEntry.hidden=NO;
        closeButton.hidden=NO;
        status=@"DoNothing";
    }
    
    int topBorder=30;
    if(theMessage.hidden){
        if(groupTheMessages)topBorder=30;
        theTable.frame=CGRectMake(10,100+topBorder,300,[[UIScreen mainScreen] bounds].size.height -160-topBorder);
    }
    
    
    
    deleteEntries.hidden=refreshMessages.hidden;
    if(groupTheMessages){
        tapEntry.text=@"Tap Match\nto open";
        closeButton.hidden=YES;
        if([myMessagePackets count]>0){
            if([[myMessagePackets objectAtIndex:0] isEqual:@"No messages"]){
                tapEntry.text=@"You can only send\nmessages to a match";
                deleteEntries.hidden=YES;
                messagesFromTo.hidden=YES;
                messagesToFromBackground.hidden=YES;
            }else{
                messagesFromTo.text=[NSString stringWithFormat:@"Messages grouped by Match:"];
                messagesFromTo.hidden=NO;
                messagesToFromBackground.hidden=NO;
            }
        }
    }else{
        tapEntry.text=@"Tap Message\nto respond";
        messagesFromTo.hidden=!theMessage.hidden;
        messagesToFromBackground.hidden=!theMessage.hidden;
        closeButton.hidden=tapEntry.hidden;
        if([myMessagePackets count]>0)
            if([[myMessagePackets objectAtIndex:0] isEqual:@"No messages"]){
                tapEntry.text=@"No entries\nfor this Match";
                deleteEntries.hidden=YES;
                
                //don't sho these if keyboard is showing
                tapEntry.hidden=!cancelMessage.hidden;
                closeButton.hidden=!cancelMessage.hidden;
            }
    }
    
    
    
    
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    dateFormat=[[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MMM dd  h:mm a"];
    fullDateFormat=[[NSDateFormatter alloc] init];
    [fullDateFormat setDateFormat:@"MMM dd  h:mm:ss a"];
    requestGetMessage=NO;
    
    
    
    float heigntValue=[[UIScreen mainScreen] bounds].size.height -345    -30;
    theMessage.frame=CGRectMake(45,30+ heigntValue, 250, 88);
    sendButton.frame=CGRectMake(13, heigntValue,82, 30);
    showMatch.frame=CGRectMake(110, heigntValue, 100, 30);
    buttonBackground.frame=CGRectMake(10, heigntValue,300, 30);
    cancelMessage.frame=CGRectMake(240, heigntValue, 59, 30);
    
    
    
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
    
    
  //  NSLog(@"viewDidLoad Message Controller");
    
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
    
    
    if(range.location<[theMessage.text rangeOfString:@"  \n"].location+3 ){//   theMessage.text.length-range.length<38){
        
        //theMessage.text=[theMessage.text substringToIndex:38];
     //   NSLog(@"here s");
        return NO;
    }else{
     //   NSLog(@"here r");
        return ![UIApplication sharedApplication].networkActivityIndicatorVisible;
        
    }
}


-(IBAction)getMessages:(id)sender{
 
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(newNotificationArrived) object:nil];
    requestGetMessage=NO;
    //  download any new messages, save them, clear the record and resave, then reload the table.
 
 
 //   NSLog(@"getting messages");
 //   [self cancelMessage:nil];
 
    if([[parameters objectForKey:@"iCloudRecordID"] intValue]!=0){
        
      //  NSLog(@"get messages");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MessagesProcedures" object:@"GetMessages"];
        
        
        
    }
}

         

-(void)resetTheTable{
   //   NSLog(@"reset the table");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    status=@"DoNothing";
    [self redoTheScreen];
    [theTable reloadData];
    [theTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[myMessagePackets count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}


-(void)refreshNotificationsIssueAlertIf:(BOOL)issueAlert{
    
    
    
    
    
}

-(void)resetTheBadge{  // best to do this only after a recent getMessages but not so bad if not

    //   want to set the badge to the number of messages that have not yet been read and are labelled 'just downloaded" - want to do the same to the app icon badge.
    
    long numberOfMessages=0;
    for(int I=0;I<[myMessages count];I++){
        if([[myMessages objectAtIndex:I] isKindOfClass:[NSDictionary class]]){
            if([[[myMessages objectAtIndex:I] objectForKey:@"Read"] isEqualToString:@"Just downloaded"])
                numberOfMessages++;
        }
    }
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:numberOfMessages];
    if(numberOfMessages==0){
        [[self tabBarItem] setBadgeValue:nil ];
    }else{
        [[self tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%li",numberOfMessages] ];
    }
//    CKModifyBadgeOperation *resetBadge=[[CKModifyBadgeOperation alloc] initWithBadgeValue:numberOfMessages];
//    [[CKContainer defaultContainer] addOperation:resetBadge];
    
    
  
    
    
}

-(void)callNewNotificationArrivedAfterDelay{ // can be called by app delegate
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self performSelector:@selector(newNotificationArrived) withObject:nil afterDelay:2.0f];
}


-(void)newNotificationArrived{
    if (refreshMessages.hidden ){  // composing a message to send
        requestGetMessage=YES;
    }else{
     //   NSLog(@"E");
        [self getMessages:nil];
    }
}


-(void)viewWillAppearStuff{  // can be called by app delegate
    
    //   moved stuff to end from here
    
    //  [theMessage becomeFirstResponder];
  
    //   NSUserDefaults *localDefaults=[NSUserDefaults standardUserDefaults];
    
    
    [subscriptionsSwitch setOn:[[parameters objectForKey:@"SubscriptionSwitch"] boolValue] animated:NO];
    
    if([parameters objectForKey:@"Match ID"] && [[parameters objectForKey:@"ReadAndAgreedTo"] boolValue]){
    
        now=[[NSDate alloc] init];
        theMessage.text=[NSString stringWithFormat:@"To:  %@   From: %i-%@\n             Date: %@  \nWe Match.  If you are interested in Ride Sharing please respond to this message.",[parameters objectForKey:@"Match ID"],[[parameters objectForKey:@"iCloudRecordID"] intValue],[[@"ABCDE" substringFromIndex:[[parameters objectForKey:@"RideSelected"]  intValue] ] substringToIndex:1],[dateFormat stringFromDate:now]];
        
        groupTheMessages=NO;
        theRecordID=[NSNumber numberWithInt: [[parameters objectForKey:@"Match ID"] intValue]];
        //      [parameters removeObjectForKey:@"Match ID"];
        messagesFromTo.text=[NSString stringWithFormat:@"Messages To/From ID: %@",theRecordID];
        
        theTable.frame=CGRectMake(10,30,300,[[UIScreen mainScreen] bounds].size.height -375);
        status=@"Compose";
        [self redoTheScreen];
        [theTable reloadData];
        
        [theTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[myMessagePackets count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        
        requestGetMessage=YES; // do a get message after composition is done
        
    }else if ([[parameters objectForKey:@"ReadAndAgreedTo"] boolValue] && showMatch.hidden){
        //normal entry - but don't do this if the keyboard is showing
      //  NSLog(@"A");
        [self getMessages:nil];
        status=@"DoNothing";
        [self redoTheScreen];
        [theTable reloadData];
        [theTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[myMessagePackets count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        
    }else if ([[parameters objectForKey:@"ReadAndAgreedTo"] boolValue] ){
        //keyboard is showing
        [theMessage becomeFirstResponder];
        requestGetMessage=YES; // do a get message after composition is done
    }
    
    
    if([[parameters objectForKey:@"ReadAndAgreedTo"] boolValue] &&
       [[showKeyboard titleForState:UIControlStateNormal] isEqualToString:@"Show Disclaimer"]){
        // when first agreed to and when first loaded (if agreed to)
    
        
        
        // do i need to do this and if so in all cases?????
        //   first load,   first read and agreed to
        status=@"FirstTime";
        [self redoTheScreen]; // a new step here
        [theTable reloadData];
 //       NSLog(@"B");
   //     if(!requestGetMessage)[self getMessages:nil];  // delay, this will be done later
     //   NSLog(@"C");
    
    }
    
}



-(void)viewWillAppear:(BOOL)animated{
    
 //   NSLog(@"messages viewwillappear");
    [super viewWillAppear:animated];
 
    
    [self viewWillAppearStuff];
}

-(void)returnFromCloud:(NSNotification *)notification{
   // NSLog(@"returning from Cloud");
    if(![notification object]){//   this is the return with the unread list updated with 'from' results
        status=@"DoNothing";
        [self redoTheScreen];
        [theTable reloadData];
    }else if([[notification object] isEqual:@"ResignNoHide"]){
        //[theMessage resignFirstResponder];
    /*    showKeyboard.hidden=NO;
        theMessage.hidden=NO;
        cancelMessage.hidden=NO;
        showMatch.hidden=NO;
        buttonBackground.hidden=NO;
        sendButton.hidden=NO;*/
        theTable.frame=CGRectMake(10,30,300,[[UIScreen mainScreen] bounds].size.height -375);
        status=@"Compose1";
        [self redoTheScreen]; // this didn't used to do a construct step
        [theTable reloadData];
        
    }else if([[notification object] isEqual:@"SubscriptionSwitch"]){
        [subscriptionsSwitch setOn:[[parameters objectForKey:@"SubscriptionSwitch"] boolValue] animated:YES];
    }else if([[notification object] isEqual:@"FailedToDelete"]){
        [deleteEntries setTitle:@"Done" forState:UIControlStateNormal];
        [self deleteEntries:nil];
    }else if([[notification object] isEqual:@"DoneWithDelete"]){
        [self resetTheBadge]; // a similar action takes place in CloudKitDatabase
      //  NSLog(@"here tttt");
        
        
        
        
        [self constructMyMessagePackets];
        if([[myMessagePackets objectAtIndex:0] isEqual:@"No messages"]){  // need to show -close
            [deleteEntries setTitle:@"Done" forState:UIControlStateNormal];
            [self deleteEntries:nil];
        }else{
         //   NSLog(@"here 222222a");
            [theTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:rowToDelete inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
           // NSLog(@"here 222222b");
        }
        
        
        
        /*
        
        if([[myMessagePackets objectAtIndex:0] isEqual:@"No messages"]){  // need to show -close
            [deleteEntries setTitle:@"Done" forState:UIControlStateNormal];
            [self deleteEntries:nil];
        }else{
            NSLog(@"here 222222a");
            [self constructMyMessagePackets];
            [theTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:rowToDelete inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            NSLog(@"here 222222b");
        }
        */
        
        
        
        
    }else if([[notification object] isEqual:@"GotMessages"]){  // coming back with messages that have already been added to mymessages!!
        
        /*
        NSArray *newMessages=[notification object];
        NSMutableArray *unsortedMessages=[[NSMutableArray alloc] initWithCapacity:[newMessages count]];
        
        NSArray *theCurrentDateDs;
        if([[myMessages objectAtIndex:0] isEqual:@"No messages"]){
            theCurrentDateDs=[[NSArray alloc] init];
        }else{
            theCurrentDateDs=[myMessages valueForKey:@"DateD"];
        }
    //    NSLog(@"the myMessages is %@",myMessages);
        
        for (int I=0;I<[newMessages count]; I++){
            if(![theCurrentDateDs containsObject:[[newMessages objectAtIndex:I] objectForKey:@"DateD"]])
                    [unsortedMessages addObject:[newMessages objectAtIndex:I]];
        }
        
        NSSortDescriptor *byDateD=[[NSSortDescriptor alloc] initWithKey:@"DateD" ascending:YES];
        NSArray *sortedMessages=[unsortedMessages sortedArrayUsingDescriptors:[NSArray arrayWithObject:byDateD]];
        [myMessages addObjectsFromArray:sortedMessages];
        */
        
        
     //   NSLog(@"here sssss");
        if([myMessages count]>1 &&  [[myMessages objectAtIndex:0] isEqual:@"No messages"])[myMessages removeObjectAtIndex:0];
        
        
        
        
        
        
        
        
        // this causes it to getMessage if a notification came in while it was sending a message
        [self cancelMessage:@"ReturnFromiCloud"]; // only needed for send message - may call a getMessage again
        [theMessage setText:@""];  //  only needed for send message
        
        
        
        
        
        [self resetTheTable];
        [self resetTheBadge];   //   a similar procedure was done in CloudKitDatabase
        
        
        
        
        
        
        
        
        
        //   this was done already:
        //  [self clearNotificationsResetBadge];
        
        
        
        
    }
}

/*
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

*/
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
    
 //   NSString *subscriptionSwitchStatus=@"SubscriptionSwitchNil";
   // if(sender){
    //    subscriptionSwitchStatus=@"SubscriptionSwitch";
        [parameters setObject:[NSNumber numberWithBool:subscriptionsSwitch.isOn] forKey:@"SubscriptionSwitch"];
   // }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MessagesProcedures" object:
     @"SubscriptionSwitch"];
     
     //subscriptionSwitchStatus];


}

-(IBAction)deleteEntries:(id)sender{
    if([[deleteEntries titleForState:UIControlStateNormal] isEqualToString:@"Delete Entries"]){
        [theTable setEditing:YES animated:YES];
        [deleteEntries setTitle:@"Done" forState:UIControlStateNormal];
        [deleteEntries setTitleColor:[UIColor colorWithRed:.9 green:0 blue:0 alpha:1] forState:UIControlStateNormal];
        status=@"Delete";
   //     tapEntry.hidden=YES;
     //   closeButton.hidden=YES;
    }else{
        [theTable setEditing:NO animated:YES];
        [deleteEntries setTitle:@"Delete Entries" forState:UIControlStateNormal];
        [deleteEntries setTitleColor:[UIColor colorWithRed:0 green:122/255. blue:1 alpha:1] forState:UIControlStateNormal];
        status=@"EndDelete";
    //    tapEntry.hidden=NO;
      //  closeButton.hidden=NO;
    }
    
    [self redoTheScreen];
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
    
    
  //  NSLog(@"here sttt");
    
 /*
    NSNumber *theDateToDelete;
    if([[myMessagePackets objectAtIndex:[indexPath row]] isKindOfClass:[NSDictionary class]])
        theDateToDelete =[[[myMessagePackets objectAtIndex:[indexPath row]] objectForKey:@"DateD"] copy];
    [myMessages removeObjectAtIndex:[indexPath row]];
  */
    
    if(groupTheMessages){
        int numberToDelete=0;
        long row=[indexPath row];
        NSNumber *theIDNumberToDelete=[[myMessagePackets objectAtIndex:row] objectForKey:@"ToNumber"];
        if([theIDNumberToDelete isEqualToNumber:[parameters objectForKey:@"iCloudRecordID"]])theIDNumberToDelete=[[myMessagePackets objectAtIndex:row] objectForKey:@"From"];
        for(long I=[myMessages count]-1;I>=0;I--){
            NSDictionary *aMessage=[myMessages objectAtIndex:I];
            NSNumber *newIDNumber=[aMessage objectForKey:@"ToNumber"];
            if([[aMessage objectForKey:@"ToNumber"] isEqualToNumber:[parameters objectForKey:@"iCloudRecordID"]])newIDNumber=[aMessage objectForKey:@"From"];
            if([newIDNumber isEqualToNumber:theIDNumberToDelete]){
                numberToDelete++;
            }
        }
        if(numberToDelete>1){
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Multiple Messages" message:[NSString stringWithFormat:@"Are you certain that you want to\ndelete all %i messages\nto ID: %@",numberToDelete, theIDNumberToDelete] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"No, Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                status=@"DoNothing";
                [self redoTheScreen]; // this didn't used to do the construct step
                [theTable reloadData];
                }];
            [alert addAction:defaultAction];
            
            UIAlertAction* deleteEm = [UIAlertAction actionWithTitle:@"Yes, Delete" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {[self deleteEntriesFromIndexPath:indexPath];}];
            [alert addAction:deleteEm];
            
            [self presentViewController:alert animated:YES completion:nil];
        }else{
            [self deleteEntriesFromIndexPath:indexPath];
        }
    }else{
        [self deleteEntriesFromIndexPath:indexPath];
    }
}


-(void)deleteEntriesFromIndexPath:(NSIndexPath *)indexPath{
    
    NSMutableArray *theMessagesToDelete=[[NSMutableArray alloc] init];
    long row=[indexPath row];
    
    
    NSNumber *theIDNumberToDelete=[[myMessagePackets objectAtIndex:row] objectForKey:@"ToNumber"];
    NSNumber *theDateToDelete=[[myMessagePackets objectAtIndex:row] objectForKey:@"DateD"];
 //   BOOL needToCheckCloud=NO;
    if([theIDNumberToDelete isEqualToNumber:[parameters objectForKey:@"iCloudRecordID"]])theIDNumberToDelete=[[myMessagePackets objectAtIndex:row] objectForKey:@"From"];
    for(long I=[myMessages count]-1;I>=0;I--){
        NSDictionary *aMessage=[myMessages objectAtIndex:I];
        if(groupTheMessages){
            NSNumber *newIDNumber=[aMessage objectForKey:@"ToNumber"];
            if([[aMessage objectForKey:@"ToNumber"] isEqualToNumber:[parameters objectForKey:@"iCloudRecordID"]])newIDNumber=[aMessage objectForKey:@"From"];
            if([newIDNumber isEqualToNumber:theIDNumberToDelete]){
             //   if([[[myMessages objectAtIndex:I] objectForKey:@"Read"] isEqualToString:@"No"])
             //       needToCheckCloud=YES;
                [theMessagesToDelete addObject:[myMessages objectAtIndex:I]];
              //  [myMessages removeObjectAtIndex:I];
            }
        }else{
            if([[aMessage objectForKey:@"DateD"] isEqualToNumber:theDateToDelete]){
             //   if([[[myMessages objectAtIndex:I] objectForKey:@"Read"] isEqualToString:@"No"])
              //      needToCheckCloud=YES;
                [theMessagesToDelete addObject:[myMessages objectAtIndex:I]];
              //  [myMessages removeObjectAtIndex:I];  // removes the one entry
            }
        }
    }
    
    if([theMessagesToDelete count]>0){  // need to delete all from private db
        rowToDelete=[indexPath row];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MessagesProcedures" object:theMessagesToDelete];
    }

    
    
}






- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [myMessagePackets count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 10;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(groupTheMessages)return 60;
    if(![[myMessagePackets objectAtIndex:[indexPath row]] isKindOfClass:[NSDictionary class]]  ){
        return 60;
    }
    NSString *entry=[[myMessagePackets objectAtIndex:[indexPath row]] objectForKey:@"Message"];
    NSArray *numberOfBreaks=[entry componentsSeparatedByString:@"\n"];
    
    int numberOfLines=entry.length/30.0 +.99;
  //  NSLog(@"the values are %lu  %i  %li",(unsigned long)entry.length,numberOfLines, (long)[numberOfBreaks count]-1);
    return (numberOfLines+ [numberOfBreaks count]-1)*15 + 60;
}

-(IBAction)closeGroup:(id)sender{
    
    NSMutableArray *messagesThatAreRead=[[NSMutableArray alloc] init];
    if([[myMessagePackets objectAtIndex:0] isKindOfClass:[NSDictionary class]]){
        for(int I=0;I<[myMessagePackets count];I++){  // mark the message as 'read' if 'Just downloaded'
            if([[[myMessagePackets objectAtIndex:I] objectForKey:@"Read"] isEqualToString:@"Just downloaded"]){
                [[[myMessagePackets objectAtIndex:I] objectForKey:@"Read"] setString:@"Yes"];
                [messagesThatAreRead addObject:[[myMessagePackets objectAtIndex:I] objectForKey:@"DateD"]];
            }
        }
    }
    
    if([messagesThatAreRead count]>0){
        [self resetTheBadge];  // a similar procedure is done in CloudKitDatabase
        //[self markAsReadTheseMessageCounters:messagesThatAreRead];
  //      [[NSNotificationCenter defaultCenter] postNotificationName:@"MessagesProcedures" object:messagesThatAreRead];
    }

    groupTheMessages=YES;
    NSMutableArray *rowsCurrent=[[NSMutableArray alloc] init];
    for(long I=0;I<[myMessagePackets count];I++){
        [rowsCurrent addObject:[NSIndexPath indexPathForRow:I inSection:0]];
    }
 //   [self constructMyMessagePackets];  // now with groupthemessages=YES;
    [self redoTheScreen];
    
    
    //need to find the row that contains theRecordID
    long row=0;
    if([[myMessagePackets objectAtIndex:0] isKindOfClass:[NSDictionary class]]){
        for(long I=0;I<[myMessagePackets count];I++){
            NSDictionary *aMessage=[myMessagePackets objectAtIndex:I];
            if([theRecordID isEqualToNumber:[aMessage objectForKey:@"ToNumber"]] ||
               [theRecordID isEqualToNumber:[aMessage objectForKey:@"From"]]){
                row=I;
                break;
            }
        }
    }
    
    
    NSMutableArray *rowsAbove=[[NSMutableArray alloc] init];
    for(long I=0;I<row;I++){
        [rowsAbove addObject:[NSIndexPath indexPathForRow:I inSection:0]];
    }
    NSArray *thisRow=[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]];
    NSMutableArray *rowsBelow=[[NSMutableArray alloc] init];
    for(long I=row+1;I<[myMessagePackets count];I++){
        [rowsBelow addObject:[NSIndexPath indexPathForRow:I inSection:0]];
    }
    
    
    [theTable beginUpdates];
    [theTable deleteRowsAtIndexPaths:rowsCurrent withRowAnimation:UITableViewRowAnimationRight];
    [theTable insertRowsAtIndexPaths:thisRow withRowAnimation:UITableViewRowAnimationLeft];
    [theTable insertRowsAtIndexPaths:rowsBelow withRowAnimation:UITableViewRowAnimationBottom];
    [theTable insertRowsAtIndexPaths:rowsAbove withRowAnimation:UITableViewRowAnimationTop];
    [theTable endUpdates];
    
    
    
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *textCellIndentifier=@"TextCell";
    
    UITableViewCell *cell;
    cell=[tableView dequeueReusableCellWithIdentifier:textCellIndentifier];
  //  if(cell==nil)cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:textCellIndentifier];
    if(cell==nil)cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:textCellIndentifier];
    
    if([[myMessagePackets objectAtIndex:[indexPath row]] isKindOfClass:[NSDictionary class]]  ){
        
        NSDictionary *aMessage=[myMessagePackets objectAtIndex:[indexPath row]];
        NSString *theFormatedDate;
        if([[aMessage objectForKey:@"DateD"]  isKindOfClass:[NSDate class]]){
            theFormatedDate=[dateFormat stringFromDate:[aMessage objectForKey:@"DateD"]];
        }else{
            theFormatedDate=[dateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:[[aMessage objectForKey:@"DateD"] doubleValue]]];
        }
        
        
        cell.detailTextLabel.numberOfLines=2;
        cell.textLabel.font=[UIFont boldSystemFontOfSize:16];
        cell.detailTextLabel.font=[UIFont systemFontOfSize:11];
        cell.detailTextLabel.textColor=[UIColor darkGrayColor];
        //    cell.imageView.image=[UIImage imageNamed:@"twitter2.png"];
        if([aMessage objectForKey:@"Read"]){
            if([[aMessage objectForKey:@"Read"] isEqualToString:@"Just downloaded"]){
                cell.imageView.image=[UIImage imageNamed:@"dot.png"];
            }else if([[aMessage objectForKey:@"Read"] isEqualToString:@"No"] || [[aMessage objectForKey:@"Read"] isEqualToString:@"Just saved"]){
                cell.imageView.image=[UIImage imageNamed:@"arrow.png"];
            }else if([[aMessage objectForKey:@"Read"] isEqualToString:@"Yes"] &&
                     ![[aMessage objectForKey:@"ToNumber"] isEqualToNumber:[parameters objectForKey:@"iCloudRecordID"]]){
                cell.imageView.image=[UIImage imageNamed:@"arrowgrey.png"];
            }else{
                cell.imageView.image=[UIImage imageNamed:@"blank line.png"];
            }
        }
        
        if(groupTheMessages){
            int theNumber=[[aMessage objectForKey:@"ToNumber"] intValue];
            if([[aMessage objectForKey:@"ToNumber"] isEqualToNumber:[parameters objectForKey:@"iCloudRecordID"]])
                theNumber=[[aMessage objectForKey:@"From"] intValue];
            cell.textLabel.text=[NSString stringWithFormat:@"%i        %@",theNumber,theFormatedDate];
            cell.detailTextLabel.text=  [aMessage objectForKey:@"Message"];
          
        }else{
            NSArray *numberOfBreaks=[[aMessage objectForKey:@"Message"] componentsSeparatedByString:@"\n"];
            
            cell.detailTextLabel.numberOfLines=[[aMessage objectForKey:@"Message"] length]/30.0 + [numberOfBreaks count];
            cell.textLabel.numberOfLines=2;
            cell.textLabel.font=[UIFont boldSystemFontOfSize:13];
            cell.detailTextLabel.font=[UIFont systemFontOfSize:13];
            cell.detailTextLabel.text=[aMessage objectForKey:@"Message"];
            if([[aMessage objectForKey:@"ToNumber"] isEqualToNumber:[parameters objectForKey:@"iCloudRecordID"]]){
                cell.textLabel.text=[NSString stringWithFormat:@"From: %i-%@    To:  %i-%@\n           Date: %@",[[aMessage objectForKey:@"From"] intValue],[aMessage objectForKey:@"FromRide"],[[aMessage objectForKey:@"ToNumber"] intValue],[aMessage objectForKey:@"ToRide"],theFormatedDate];
            }else{  // I sent this message to someone
                //   NSLog(@"a message is %@",aMessage);
                cell.textLabel.text=[NSString stringWithFormat:@"To:  %i-%@    From: %i-%@\n           Date: %@",[[aMessage objectForKey:@"ToNumber"] intValue],[aMessage objectForKey:@"ToRide"],[[aMessage objectForKey:@"From"] intValue],[aMessage objectForKey:@"FromRide"],theFormatedDate];
            }
            
        }
        
        if([[deleteEntries titleForState:UIControlStateNormal] isEqualToString:@"Done"]){
            cell.textLabel.font=[UIFont boldSystemFontOfSize:11];
            cell.detailTextLabel.font=[UIFont systemFontOfSize:9];
        }
        
        
    
        
        
    }else{
        cell.textLabel.font=[UIFont boldSystemFontOfSize:16];
        cell.textLabel.text=@"        No messages\n";
        cell.detailTextLabel.text=@"";
        cell.imageView.image=[UIImage imageNamed:@"blank.png"];
    }
    
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:223/255. green:255/255. blue:1.0 alpha:1.0];
    [cell setSelectedBackgroundView:bgColorView];
    
    
    
    return cell;
}



-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    long row=[indexPath row];
    if ([[myMessagePackets objectAtIndex:[indexPath row]] isEqual:@"No messages"]){
        status=@"DoNothing";
        [self redoTheScreen]; // this didn't used to do the construct step
        [theTable reloadData];
        return;
    }
    if(groupTheMessages){
        groupTheMessages=NO;
        NSDictionary *aMessage=[myMessagePackets objectAtIndex:row];
        theRecordID=[aMessage objectForKey:@"ToNumber"];
        if([theRecordID isEqualToNumber:[parameters objectForKey:@"iCloudRecordID"]]){ // this message was sent to me, i am responding
            theRecordID=[aMessage objectForKey:@"From"];
        }
        
        //make a set with all index path rows lower than this row.
        // make another set wiyth index path rows higher than this row
        // make a set with this index path row
        // make a set with indexpaths for all the new rows [mymessagepackets count]
        // do it
        
        NSMutableArray *rowsAbove=[[NSMutableArray alloc] init];
        for(long I=0;I<row;I++){
            [rowsAbove addObject:[NSIndexPath indexPathForRow:I inSection:0]];
        }
        NSArray *thisRow=[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]];
        NSMutableArray *rowsBelow=[[NSMutableArray alloc] init];
        for(long I=row+1;I<[myMessagePackets count];I++){
            [rowsBelow addObject:[NSIndexPath indexPathForRow:I inSection:0]];
        }
    //    [self constructMyMessagePackets];  // now with groupthemessages=no;
        [self redoTheScreen];
        
        
        NSMutableArray *newRows=[[NSMutableArray alloc] init];
        for(long I=0;I<[myMessagePackets count];I++){
            [newRows addObject:[NSIndexPath indexPathForRow:I inSection:0]];
        }
        [tableView beginUpdates];
        [tableView insertRowsAtIndexPaths:newRows withRowAnimation:UITableViewRowAnimationRight];
        [tableView deleteRowsAtIndexPaths:rowsAbove withRowAnimation:UITableViewRowAnimationTop];
        [tableView deleteRowsAtIndexPaths:thisRow withRowAnimation:UITableViewRowAnimationLeft];
        [tableView deleteRowsAtIndexPaths:rowsBelow withRowAnimation:UITableViewRowAnimationBottom];
        [tableView endUpdates];
        
        
        
        messagesFromTo.text=[NSString stringWithFormat:@"Messages To/From ID: %@",theRecordID];
        [theTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[myMessagePackets count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        
    }else{
        
        if([[myMessagePackets objectAtIndex:[indexPath row]] isKindOfClass:[NSDictionary class]]  ){
            NSString *postThisMessage;
            NSDictionary *aMessage=[myMessagePackets objectAtIndex:[indexPath row]];
            now=[[NSDate alloc] init];
            if([[aMessage objectForKey:@"ToNumber"] isEqualToNumber:[parameters objectForKey:@"iCloudRecordID"]]){ // this message was sent to me, i am responding
                postThisMessage=[NSString stringWithFormat:@"To:  %i-%@   From: %i-%@\n             Date: %@  \n",[[aMessage objectForKey:@"From"] intValue],[aMessage objectForKey:@"FromRide"],[[aMessage objectForKey:@"ToNumber"] intValue],[aMessage objectForKey:@"ToRide"],[dateFormat stringFromDate:now]];
                
            }else{  // i am responding to a message I sent, this is another message to same person
                postThisMessage=[NSString stringWithFormat:@"To:  %i-%@   From: %i-%@\n             Date: %@  \n",[[aMessage objectForKey:@"ToNumber"] intValue],[aMessage objectForKey:@"ToRide"],[[aMessage objectForKey:@"From"] intValue],[aMessage objectForKey:@"FromRide"],[dateFormat stringFromDate:now]];
            }
            theMessage.text=postThisMessage;
            status=@"Compose";
            [self redoTheScreen];
            [theTable reloadData];
          /*  theMessage.hidden=NO;
            [theMessage becomeFirstResponder];
            cancelMessage.hidden=NO;
            showMatch.hidden=NO;
            buttonBackground.hidden=NO;
            sendButton.hidden=NO;
            tapEntry.hidden=YES;
            deleteEntries.hidden=YES;
            alertsLabel.hidden=YES;
            refreshMessages.hidden=YES;
            messagesFromTo.hidden=YES;
            messagesToFromBackground.hidden=YES;
            closeButton.hidden=YES;
            subscriptionsSwitch.hidden=YES;
            infoButton.hidden=YES;*/
            
      //      theTable.frame=CGRectMake(10,30,300,[[UIScreen mainScreen] bounds].size.height -375);
            theTable.frame=CGRectMake(10,30,300,[[UIScreen mainScreen] bounds].size.height -405);
            [theTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            
            
            
            
            
            
            if([[[myMessagePackets objectAtIndex:[indexPath row]] objectForKey:@"Read"] isEqualToString:@"Just downloaded"]){
                [[[myMessagePackets objectAtIndex:[indexPath row]] objectForKey:@"Read"] setString:@"Yes"];
                [self resetTheBadge];
            }
            
            
            
            
            
            
            
        }
        
    }
    
    
    
}


@end
