//
//  ChoicesViewController.h
//  Group Draw
//
//  Created by Peter B. Kramer on 7/6/13.
//  Copyright (c) 2013 Peter B. Kramer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>


@interface ChoicesViewController : UIViewController <UIWebViewDelegate,MFMailComposeViewControllerDelegate ,UITextViewDelegate>{
    
    IBOutlet UITextView *aboutText;
    long theChoice;
    IBOutlet UIWebView *twitterOrFacebookWebView;
    IBOutlet UIActivityIndicatorView *goingToWeb;
    IBOutlet UIImageView *arrow;
    IBOutlet UISegmentedControl *iAgree;
}

-(void)selectionIs:(long)segmentIndex;
-(void)getParameters:(NSMutableDictionary *)theParameters;

@end
