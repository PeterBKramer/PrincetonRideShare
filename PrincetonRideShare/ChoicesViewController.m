//
//  ChoicesViewController.m
//  Group Draw
//
//  Created by Peter B. Kramer on 7/6/13.
//  Copyright (c) 2013 Peter B. Kramer. All rights reserved.
//

#import "ChoicesViewController.h"

//#import <MessageUI/MessageUI.h>
//#import <MessageUI/MFMailComposeViewController.h>


@interface ChoicesViewController (){
    NSMutableDictionary *parameters;
}

@end

@implementation ChoicesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    
    return self;
}


-(void)getParameters:(NSMutableDictionary *)theParameters{
    parameters=theParameters;
}

-(IBAction)iAgree:(id)sender{
    
//    NSLog(@"the sender is %@",sender);
    if([sender isKindOfClass:[UIBarButtonItem class]] || iAgree.selectedSegmentIndex==1)
            [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"ReadAndAgreedTo"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)dismissThisView{
    if(twitterOrFacebookWebView.delegate)twitterOrFacebookWebView.delegate=nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad{
    UIBarButtonItem *cancelButton =[[UIBarButtonItem alloc] initWithTitle: @"Done" style:UIBarButtonItemStyleDone target: self action: @selector(dismissThisView)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    aboutText.delegate=self;
    
    //  then About = 1, Contact Us =2, Review App = 3, //twitter = 4, Facebook=5
    
    if(theChoice==5){
        twitterOrFacebookWebView.hidden=NO;
        [twitterOrFacebookWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://m.facebook.com"]]];
//            [twitterOrFacebookWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://m.twitter.com"]]];
        [goingToWeb startAnimating];
        twitterOrFacebookWebView.delegate=self;
        self.title=@"Facebook";
        arrow.hidden=YES;
    }else if(theChoice==4){
        twitterOrFacebookWebView.hidden=NO;
        [twitterOrFacebookWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://m.twitter.com"]]];
        [goingToWeb startAnimating];
        twitterOrFacebookWebView.delegate=self;
        self.title=@"Twitter";
        arrow.hidden=YES;
    }else if (theChoice==3){
        aboutText.hidden=NO;
        aboutText.text=@"Instructuions.....";
        aboutText.textAlignment=NSTextAlignmentLeft;
        aboutText.font=[UIFont systemFontOfSize:14];
        self.title=@"Instructions";
        aboutText.text=@"Introduction:\n     \"Carpooling: Princeton Ride Share\" is an app that connects users with matching carpooling needs in the Princeton, New Jersey area.  On the \"My Info\" page you enter information on your needs.  On the \"Match\" page you identify users with matching needs.  On the \"Message\" page you send messages to users to initiate a discussion about carpooling.  This App uses Apple’s iCloud Drive function to match carpool requests - you may be asked to log into iCloud from the Settings App and to allow ‘Ride Share’ to use your iCloud space.  Please read the Privacy, Safety and Disclaimer sections below for important information.\n\nMy Info:\n     On the \"My Info\" page you enter information on up to 5 different, independent Rides; each Ride consists of a ‘Home’ location, a ‘Work’ location, the time interval for arriving at the ‘Work’ location and/or the time interval for leaving the ‘Work location, the days of the week that you wish to make the Ride, and whether you will be providing the car for the Ride.\n\nMatch:\n     On the \"Match\" page the App searches the Rides entered by other users of the App and displays on a map the ‘Home’ and ‘Work’ location of those Rides that match.  A Match occurs when the other user’s ‘Home’ location is within 10 kilometers (6 miles) of your ‘Home’ location for your selected Ride.  You may also turn on ‘Match times’ and the App will display only those Rides that are within 10 kilometers of your ‘Home’ location, at least partially overlap either your arriving or leaving time interval, match one or more of your days of the week, and fit whether you will or will not be providing a car.  Each Match is annotated with a color coded graphic that indicates the overlap times and days.  By selecting one of those annotations you can send a message to that other user.\n\nMessage:\n     On the \"Message\" page you can send or receive a message to or from other users of the App if you have a matching Ride.  If you allow this App to send you Notifications then you will be notified whenever another user sends a message to you.  Through these messages you can ascertain whether the other user might be appropriate for your carpooling needs and arrange to meet with that other user.\n\nPrivacy:\n     This App does not use your information for any purpose except to allow you to match your carpooling needs with other users.  This App uses an anonymous, randomly selected number to identify you to other users.  Your ‘Home’ and ‘Work’ locations are displayed on a map and associated with this anonymous number only.  Messages sent from you to other users display only this anonymous number to the other users.  If you are concerned that your precise ‘Home’ or ‘Work’ location might reveal your identity and you do not wish to do that, then you may use a nearby street intersection as a ‘Home’ or ‘Work’ location.  You may reveal your identity to other users of the App by disclosing your name, email address or phone number in a message sent to that user; however, please read ‘Safety’ and ‘Disclaimer’ below.\n\nSafety:\n     You are responsible for your own safety.  No effort has been made to qualify any user of this app.  There are crazies out there; before revealing your identity, meeting, or ride sharing with any other user of this app, remember that you are responsible for ascertaining that the other user has no ill intention.  And driving accidents happen; you are responsible for being certain that you and/or your ride sharers are properly skilled, licensed and insured.\n\nDisclaimer:\n     Before being able to send or receive a message, you will be asked to agree that you have read about the above safety concern and agree that the developers of this App are not liable for any damages, etc., etc., etc..  Sorry, but accidents and bad things happen.";
        
    }else if (theChoice==7){
        aboutText.hidden=NO;
        aboutText.text=@"choice is 7";
        aboutText.textAlignment=NSTextAlignmentLeft;
        aboutText.font=[UIFont systemFontOfSize:14];
        self.title=@"The Message Page";
        aboutText.text=@"     This page allows you to compose a Message to send to another user and shows Messages that you have sent or received.\n\n     Before you can send or receive Messages you must read and agree to a Disclaimer statement.  All Messages are sent to and from anonymous users identified only by their iCloud Drive Id number which is randomly assigned to each device.  Using these Messages you may determine that a particular anonymous user is a good prospect for carpooling and agree to meet or share non-anonymous identifying information to that user.  However, please read the safety information in the disclosure before revealing your identity.\n\n     To send a Message to a matching user, tap the map annotation of a Match on the \"Match\" page and then tap \"Send Message\".  Alternatively, tap any previous Message that you sent to, or received from, that user.  Compose the Message and tap \"Send\".  A Message that has not yet been retrieved by its recipient will be blue.  When a Message is retrieved by its recipient it will change to black.\n\n     To identify, on the map, the matching Rides of a sender or recipient of a Message, tap the Message and then tap \"Show Match\".  The annotation numbered \"1\" will be the specific matching Ride associated with the Message.\n\n     Each time you open this page the App goes out to iCloud and retrieves any new Messages.  New Messages just downloaded will be red.  While viewing this page you can refresh your Messages by tapping the circular refresh icon.\n\n     To delete any Message tap \"Delete Entries\" and then the red button and the \"Delete\" square.  Alternatively, swipe any message to the left and press the \"Delete\" square.  If you delete a Message that you sent before it is retrieved by its intended recipient, then that Message will no longer be retrieveable by that recipient.\n\n     This App can send you Notifications that new Messages have been sent to you and are ready for retrieval.  To receive Notifications turn on \"Alerts:\".  You may need to authorize this App to receive Notifcations using your Settings App.  All devices logged into the same iCloud Account share their alert Notifications but they do not share their Messages.\n\n";
    }else if (theChoice==6){
        aboutText.hidden=NO;
        aboutText.text=@"choice is 6";
        aboutText.textAlignment=NSTextAlignmentLeft;
        aboutText.font=[UIFont systemFontOfSize:14];
        self.title=@"The Match Page";
        aboutText.text=@"     This page shows Matches for your selected Ride.  (Please read \"Matching Strategies\" below.)  Each time the page is opened (or the refresh icon tapped) the App goes to iCloud and downloads all Rides with a 'Home' location within 10 kilometers (6 miles) of your selected Ride's 'Home' location.  These Rides are then ordered and numbered according to their distance from your 'Home' location.  Their 'Home' and, if specified, 'Work' location are annotated on the map.  A white annotation with a black number is a 'Home' location.  A black annotation with a white number is a 'Work' location.  If multiple Rides overlap the same map location, the annotation is marked with an \"M\" rather than a number.  If an annotation includes both a 'Home' location and a 'Work' location it is grey.\n\n     Use the control at the top to select one of your 5 independent Rides: A, B, C, D or E.\n\n     Tap one of the annotations to display the Ride information for that Match.  A checkmark indicates an overlap and an x indicates a mismatch. From this display you can show the 'Work' (or 'Home') location of this Match or send a matching user a message.\n\n     Select \"Match times\" to see only those Matches that overlap one of your trip's time intervals, one of your days of the week and your car use requirement.  The 'Home' and 'Work' location on the map will be annotated with a graphic indicating the overlaps.  On the top of that graphic is a set of 7 small boxes corresponding to the 7 days of the week, from Monday through Sunday, each box colored green, red, white or yellow.  Green indicates all parties want to carpool on that day, red indiates only one of the two matching parties wants to carpool on that day and white indicates that no party wants to carpool on that day. Yellow indicates that the annotation includes multiple Matches and that one or more of those Matches is green and one or more red.  The graphic also includes a top and bottom stripe of one or more colors.  The top stripe corresponds to the time interval for the trip from 'Home' to 'Work' and the bottom stripe corresponds to the time interval for the trip from 'Work' back to 'Home'.  From left to right on each stripe corresponds to your starting time of that time interval through to your ending time of that time interval.  If there is an overlapping time during that time interval it is colored green.  If there is a non-overlapping time during that time interval, it is colored red.  And if there are multiple matches and some are green and some are red, then it is colored yellow.  Finally, if there is a perfect match (i.e. some overlapping times for both trips and agreement on all days of the week) then the center square is colored green.\n\n     Again, tap one of the graphic annotations to display the Ride information for that Match.  If the annotation includes multiple Matches, the graphic describing each Match will be shown.  Tapping that graphic will display the Ride information for that individual Match.  From this display you can chose to send any individual matching user a message.\n\n\nMatching Strategies:\n     This App is used to communicate carpooling needs among users and find appropriate matches between users.  It uses a 'Home' location and orders users based on their distance from that 'Home' location out to 6 miles.  It may be useful to adjust your 'Home' location to find appropriate Matches.  For example, if you live near Route 1 you might be willing to drive your car to a Route 1 location and leave it there.  In which case you might indicate a 'Home' location as being on Route 1.  And you might place a 'Home' location 6 miles up Route 1 in search of a Match with a person whose 'Home' location is more than 6 miles from your actual home but who commutes down Route 1 past your actual home.  Conversely, if you are commuting down Route 1 you might set a 'Home' location along Route 1 quite distant from your actual home location in search of a Match that is along your commuting path.  When searching for a Match, similar considerations can be applied to a potential Match's 'Work' location.\n     To increase the possibility of finding a Match, it may be useful to show as much flexibility as possible in defining your arriving and leaving time intervals and whether or not you will supply the car (chose \"Either\" if possible).\n     This App can also be used to Ride Share from one location to a repeating event such as a weekly practice.  To do that, make the first location the 'Home' location and make the practice location the 'Work' location.  Then select only those Matches that display a 'Work' graphic near the practice location.  Tell other practice participants to do the same.";
        
    }else if (theChoice==9){
        aboutText.hidden=NO;
        aboutText.text=@"choice is 9";
        aboutText.textAlignment=NSTextAlignmentLeft;
        aboutText.font=[UIFont systemFontOfSize:14];
        self.title=@"The Info Page";
        aboutText.text=@"     Select one of 5 independent Rides; A, B, C, D or E.\n\n     Set your 'Home' location for the selected Ride by tapping \"Set 'Home'\" and then finding your location on the map and tapping it.  You may chose to tap a nearby intersection or parking lot rather than your exact home location for privacy or other reasons.  Do the same for your 'Work' location.\n\n     Set a time interval for arriving at 'Work'(tap \"Set times\") for the selected Ride's trip from 'Home' to 'Work' or set a time interval for leaving 'Work' for the selected Ride's trip from 'Work' to 'Home' or set time intervals for both trips. Once set, a trip can be canceled by tapping \"Cancel leaving from 'Home'\" or \"Cancel returning to 'Home'\".\n\n     Select the days of the week for this selected Ride by tapping the letter for that day.  Capital letters indicate a selected day.\n\n     Select whether you must use your car, whether you cannot provide a car or \"Either\".\n\n     Matches require a 'Home' location.  If you also wish to 'Match times' you must select a time interval for one of the two possible trips.  You do not need to specify a 'Work' location to find a Match although it would be helpful.";
        
        if([[UIScreen mainScreen] bounds].size.height>700){
            arrow.hidden=YES;
            aboutText.frame=CGRectMake(19, 93, 283, 380);
        }
        
    }else if (theChoice==1){
        aboutText.hidden=NO;
        aboutText.text=@"Princeton Ride Share V1.1\n\nKramer & Kramer Software\n\n©2015 by:\n Balaji Chennawar\nKiran Murty\nPeter Kramer.\nAll rights reserved.\n\nSpecial thanks to my friends at www.stackoverflow.com.\nTab bar icons courtesy of Joseph Wain glyphish.com under the license http://creativecommons.org/licenses/by/3.0/us/   ";
        aboutText.textAlignment=NSTextAlignmentCenter;
        aboutText.font=[UIFont boldSystemFontOfSize:18];
        self.title=@"About";
        
        
        
        arrow.hidden=YES;
        if([[UIScreen mainScreen] bounds].size.height>700){
            aboutText.frame=CGRectMake(19, 93, 283, 260);
        }else if([[UIScreen mainScreen] bounds].size.height>600){
            aboutText.frame=CGRectMake(19, 93, 283, 300);
        }else if([[UIScreen mainScreen] bounds].size.height>480){
            aboutText.frame=CGRectMake(19, 93, 283, 400);
        }else{
            arrow.hidden=NO;
        }
        
        
    }else if (theChoice==2 || theChoice==8){
        aboutText.hidden=NO;
        aboutText.text=@"IMPORTANT:\n\nYOU are responsible for your own safety.  No effort has been made to qualify any user of this app.\n\nThere are crazies out there; before revealing your identity, meeting, or ride sharing with any other user of this app, remember that YOU are responsible for ascertaining that the other user has no ill intention.\n\nAnd driving accidents happen; YOU are responsible for being certain that you and/or your ride sharers are properly skilled, licensed and insured.\n\nAll information is provided 'as is' and solely for informational purposes and without warranty of any kind.  Kramer & Kramer Software and its partners are not liable for any actions taken in reliance on information contained herein and not responsible for, and expressly disclaim all liability for damages, losses, demands, actions, debts and attorney's fees of any kind arising out of the use of information provided by this app.";
        aboutText.textAlignment=NSTextAlignmentCenter;
        aboutText.font=[UIFont boldSystemFontOfSize:18];
        self.title=@"Disclaimer";
        if(theChoice==8){
            aboutText.text=[@"\n\n\n\n\nRead and scroll to bottom\nto display \"I Agree\" button.\n\n\nYou must read and agree to this Disclaimer before sending or receiving any messages.\n\n\n\n\n\n" stringByAppendingString:aboutText.text];
          //  self.navigationItem.leftBarButtonItem = nil;
            [self.navigationItem.leftBarButtonItem setTitle:@"I Do Not Agree"];
            
        }
 
    }else if (theChoice>100000  || theChoice==0){
        [self showMailComposer];
        self.title=@"Contact Us";
        arrow.hidden=YES;
    }
    
    [self.navigationController.navigationBar setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
        [UIFont boldSystemFontOfSize:20],NSFontAttributeName, nil]];



    [super viewDidLoad];


//    NSLog(@"here in chices");
    // Do any additional setup after loading the view from its nib.
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    float bottom=scrollView.contentSize.height-scrollView.frame.size.height;
    //   readAndAgreedTo.hidden=(disclaimerText.contentOffset.y< bottom-8.0);
    if(scrollView.contentOffset.y> bottom-8.0){
        arrow.hidden=YES;
        if(theChoice==8){
            UIBarButtonItem *agreeButton =[[UIBarButtonItem alloc] initWithTitle: @"I Agree" style:UIBarButtonItemStyleDone target: self action: @selector(iAgree:)];
            self.navigationItem.rightBarButtonItem = agreeButton;
            iAgree.hidden=NO;
        }
    }else{
        arrow.hidden=NO;
        if(theChoice==8){
            self.navigationItem.rightBarButtonItem = nil;
            iAgree.hidden=YES;
        }
    }
}

-(void)selectionIs:(long)segmentIndex{
    theChoice=segmentIndex;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
 //   NSLog(@"FINISHED");
    [goingToWeb stopAnimating];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Web Error" message:@"An error occured while\ntrying to retrieve this website." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Sorry" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {[self dismissThisView];}];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}


-(void) showMailComposer{
    Class mailClass=(NSClassFromString(@"MFMailComposeViewController"));
    if(mailClass!=nil){
        if([mailClass canSendMail]){
            MFMailComposeViewController  *picker=[[MFMailComposeViewController alloc] init];
            picker.mailComposeDelegate=self;
            [picker setSubject:@"Feedback on Princeton Ride Share V1.1"];
            NSString *deviceIdIs=[NSString stringWithFormat:@"\n(No iCloud Drive Id assigned)"];
            if(theChoice>100000)deviceIdIs=[NSString stringWithFormat:@"\n(iCloud Drive Id: %li.)",theChoice];
            NSString *emailBody=[NSString stringWithFormat: @"Please type your comments here:\n\n\n\n%@",deviceIdIs];
            
            
         //   NSLog(@"the mail line will be %@",emailBody);
            
            
            NSMutableArray *toRecipients=[[NSMutableArray alloc] init];
            [toRecipients addObject:[NSString stringWithFormat:@"CustomerService@KramerAndKramerSoftware.com"]];
            [picker setToRecipients:toRecipients];
            [picker setMessageBody:emailBody isHTML:NO];
            //[self presentModalViewController:picker animated:YES];
            picker.modalPresentationStyle=UIModalPresentationFormSheet;
            //  picker.modalTransitionStyle=UIModalTransitionStyleCrossDissolve;
            picker.modalTransitionStyle=UIModalTransitionStyleFlipHorizontal;
            //  picker.modalTransitionStyle=UIModalTransitionStylePartialCurl;
            
            picker.view.tintColor=[UIColor colorWithRed:.9 green:.0 blue:0 alpha:1.0];
            [self presentViewController:picker animated:YES completion:NULL];
            
        }else{
            
       //     NSLog(@"Cant send mail");
            
            
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Unable to Email" message:@"This device is not configured\nto send emails.  You may reach us at CustomerService@KramerAndKramer\nSoftware.com" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
            [self dismissThisView];
        }
    }
    
}

-(void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    NSString *resultTitle=nil;
    NSString *resultMsg=nil;
    
    
    [self dismissThisView];
    
    if(result==MFMailComposeResultSent){
        resultTitle=@"Email Sent";
        resultMsg=@"Thanks, your email was successfully sent.";
        
        
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:resultTitle message:resultMsg preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {[self dismissThisView];}];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    
    }else if(result==MFMailComposeResultFailed || error) {
        resultTitle=@"Email Not Sent";
        resultMsg=@"Sorry, the Mail Composer failed.\nYou may reach us at CustomerService@KramerAndKramer\nSoftware.com";
        
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:resultTitle message:resultMsg preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {[self dismissThisView];}];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
   
    }else{
         [self performSelector:@selector(dismissThisView) withObject:nil afterDelay:.4f];
    }
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
