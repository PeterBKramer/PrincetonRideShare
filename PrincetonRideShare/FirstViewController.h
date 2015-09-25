//
//  FirstViewController.h
//  PrincetonRideShare
//
//  Created by Peter B Kramer on 6/6/15.
//  Copyright (c) 2015 Peter B Kramer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirstViewController : UIViewController{
    
    IBOutlet UITextView *textDisplay;
    IBOutlet UIView *containingView;
    IBOutlet UILabel *uniqueID;
    
    
    
}

-(void)getParameters:(NSMutableDictionary *)theParameters;

@end

