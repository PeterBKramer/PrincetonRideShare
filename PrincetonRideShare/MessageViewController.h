//
//  MessageViewController.h
//  PrincetonRideShare
//
//  Created by Peter B Kramer on 6/7/15.
//  Copyright (c) 2015 Peter B Kramer. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <CloudKit/CloudKit.h>

@interface MessageViewController : UIViewController<UITextViewDelegate,UITableViewDelegate,UITableViewDataSource>{
    IBOutlet UILabel *buttonBackground;
    IBOutlet UILabel *messagesToFromBackground;
    IBOutlet UIButton *closeButton;
    IBOutlet UILabel *messagesFromTo;
    IBOutlet UIButton *cancelMessage;
    IBOutlet UITableView *theTable;
    IBOutlet UITextView *theMessage;
    IBOutlet UILabel *tapEntry;
    IBOutlet UIView *containingView;
    IBOutlet UILabel *alertsLabel;
    IBOutlet UISwitch *subscriptionsSwitch;
    IBOutlet UIButton *refreshMessages;
    IBOutlet UIButton *showKeyboard;
    IBOutlet UIButton *deleteEntries;
    IBOutlet UILabel *disclaimerLabel;
//    IBOutlet UIButton *disclaimerSelector;
    IBOutlet UIButton *infoButton;
    IBOutlet UIButton *showMatch;
    IBOutlet UIButton *sendButton;
}
//TODO: blah blah
-(void)getParameters:(NSMutableDictionary *)theParameters;
-(void)callNewNotificationArrivedAfterDelay;
-(void)viewWillAppearStuff;
-(void)newNotificationArrived;
//-(void)setBadgesAtStart;


@end
