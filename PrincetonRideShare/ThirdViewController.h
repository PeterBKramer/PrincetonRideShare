//
//  ThirdViewController.h
//  PrincetonRideShare
//
//  Created by Peter B Kramer on 6/7/15.
//  Copyright (c) 2015 Peter B Kramer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CloudKit/CloudKit.h>

@interface ThirdViewController : UIViewController<MKMapViewDelegate,UITableViewDataSource,UITableViewDelegate>{
        
    IBOutlet MKMapView *mapIt;
    IBOutlet UILabel *arriveB;
    IBOutlet UILabel *leaveB;
    IBOutlet UIDatePicker *fromTime;
    IBOutlet UIDatePicker *toTime;
    IBOutlet UIButton *arriveTimes;
    IBOutlet UIButton *leaveTimes;
    IBOutlet UISegmentedControl *myCarOrYoursControl;
    IBOutlet UIButton *Monday;
    IBOutlet UIButton *Tuesday;
    IBOutlet UIButton *Wednesday;
    IBOutlet UIButton *Thursday;
    IBOutlet UIButton *Friday;
    IBOutlet UIButton *Saturday;
    IBOutlet UIButton *Sunday;
    IBOutlet UIView *containingView;
    IBOutlet UISegmentedControl *rideSelector;
    IBOutlet UIButton *locationA;
    IBOutlet UIButton *locationB;
    IBOutlet UIButton *matchNearA;
    IBOutlet UIButton *infoButton;
    IBOutlet UIActivityIndicatorView *matching;
    IBOutlet UILabel *tapMatchForInfo;
    IBOutlet UISwitch *filterData;
    IBOutlet UIButton *getDataOrStop;
    IBOutlet UITableView *entriesInAGroup;
    
   
    
}
-(void)getParameters:(NSMutableDictionary *)theParameters;



@end
