//
//  SecondViewController.m
//  PrincetonRideShare
//
//  Created by Peter B Kramer on 6/6/15.
//  Copyright (c) 2015 Peter B Kramer. All rights reserved.
//

#import "SecondViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "ChoicesViewController.h"

@interface SecondViewController (){
    NSMutableArray *theRides;
    NSMutableDictionary *theSelectedRide;
    NSDateFormatter *dateFormat;
    
    MKPointAnnotation *myHome;
    MKPointAnnotation *myWork;
    
    NSMutableDictionary *parameters;
 //   MKAnnotationView *annotationView;
//    CLLocationManager *locationManager;
}

@end

@implementation SecondViewController


-(void)getParameters:(NSMutableDictionary *)theParameters{
    parameters=theParameters;
 //   NSLog(@"got parameters in second    %@",parameters);
}


-(IBAction)daysOfWeek:(UIButton *)sender{
    
    int daysOfTheWeek=0;
    if([theSelectedRide objectForKey:@"DaysOfTheWeek"])
        daysOfTheWeek=[[theSelectedRide objectForKey:@"DaysOfTheWeek"] intValue];
    if([sender isEqual:Monday]){
        if([[sender titleForState:UIControlStateNormal] isEqualToString:@"m"]){
            daysOfTheWeek=daysOfTheWeek+1;
        }else{
            daysOfTheWeek=daysOfTheWeek-1;
        }
    }else if([sender isEqual:Tuesday]){
        if([[sender titleForState:UIControlStateNormal] isEqualToString:@"t"]){
            daysOfTheWeek=daysOfTheWeek+2;
        }else{
            daysOfTheWeek=daysOfTheWeek-2;
        }
    }else if([sender isEqual:Wednesday]){
        if([[sender titleForState:UIControlStateNormal] isEqualToString:@"w"]){
            daysOfTheWeek=daysOfTheWeek+4;
        }else{
            daysOfTheWeek=daysOfTheWeek-4;
        }
    }else if([sender isEqual:Thursday]){
        if([[sender titleForState:UIControlStateNormal] isEqualToString:@"t"]){
            daysOfTheWeek=daysOfTheWeek+8;
        }else{
            daysOfTheWeek=daysOfTheWeek-8;
        }
    }else if([sender isEqual:Friday]){
        if([[sender titleForState:UIControlStateNormal] isEqualToString:@"f"]){
            daysOfTheWeek=daysOfTheWeek+16;
        }else{
            daysOfTheWeek=daysOfTheWeek-16;
        }
    }else if([sender isEqual:Saturday]){
        if([[sender titleForState:UIControlStateNormal] isEqualToString:@"s"]){
            daysOfTheWeek=daysOfTheWeek+32;
        }else{
            daysOfTheWeek=daysOfTheWeek-32;
        }
    }else if([sender isEqual:Sunday]){
        if([[sender titleForState:UIControlStateNormal] isEqualToString:@"s"]){
            daysOfTheWeek=daysOfTheWeek+64;
        }else{
            daysOfTheWeek=daysOfTheWeek-64;
        }
    }
    
    if(sender || daysOfTheWeek==0)  // update info if it is changed or will change
        [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"UpdateInformation"];
    if (daysOfTheWeek==0)daysOfTheWeek=31;
    [theSelectedRide setObject:[NSNumber numberWithInt:daysOfTheWeek] forKey:@"DaysOfTheWeek"];
    [self reDrawTheScreen];
    
}


-(IBAction)showArrivingTime:(id)sender{
    showHome.hidden=YES;
    showWork.hidden=YES;
    mapIt.hidden=YES;
    fromTime.hidden=NO;
    toTime.hidden=NO;
    timeBetween.hidden=NO;
    timeBetween.text=@"Leaving from 'Home'.\nArrive at 'Work' between the times:";
    cancelReturn.hidden=NO;
    [cancelReturn setTitle:@"Cancel leaving from 'Home'" forState:UIControlStateNormal];
    if (![theSelectedRide objectForKey:@"ArriveStart"])
        [theSelectedRide setObject:@"8:30 AM" forKey:@"ArriveStart"];
    if (![theSelectedRide objectForKey:@"ArriveEnd"])
        [theSelectedRide setObject:@"9:00 AM" forKey:@"ArriveEnd"];
    [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"UpdateInformation"];
    [self reDrawTheScreen];
}



-(IBAction)showLeavingTime:(id)sender{
    showHome.hidden=YES;
    showWork.hidden=YES;
    mapIt.hidden=YES;
    fromTime.hidden=NO;
    toTime.hidden=NO;
    timeBetween.hidden=NO;
    timeBetween.text=@"Returning to 'Home'.\nLeave 'Work' between the times:";
    cancelReturn.hidden=NO;
    [cancelReturn setTitle:@"Cancel returning to 'Home'" forState:UIControlStateNormal];
    if (![theSelectedRide objectForKey:@"LeaveStart"])
        [theSelectedRide setObject:@"5:00 PM" forKey:@"LeaveStart"];
    if (![theSelectedRide objectForKey:@"LeaveEnd"])
        [theSelectedRide setObject:@"6:00 PM" forKey:@"LeaveEnd"];
    [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"UpdateInformation"];
    [self reDrawTheScreen];
}


-(void)dateChanged:(id)sender{
    NSString *fromString=[dateFormat stringFromDate:fromTime.date];
    NSString *toString=[dateFormat stringFromDate:toTime.date];
    double timeBump=0.0;
    if([fromString rangeOfString:@"PM"].length>0 && [toString rangeOfString:@"AM"].length>0)timeBump=24*60*60;
 //   NSLog(@"12");
    [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"UpdateInformation"];
    if([timeBetween.text isEqualToString:@"Leaving from 'Home'.\nArrive at 'Work' between the times:"]){
     //   NSLog(@"121");
        [theSelectedRide setObject:fromString forKey:@"ArriveStart"];
        [theSelectedRide setObject:toString forKey:@"ArriveEnd"];
        if([toTime.date timeIntervalSinceDate:fromTime.date]+timeBump<=0){
            
        //    NSLog(@"resetting 1");
            if([sender isEqual:fromTime]){
                [theSelectedRide setObject:[dateFormat stringFromDate:[fromTime.date dateByAddingTimeInterval:30*60]] forKey:@"ArriveEnd"];
            }else{
                int fromMinutes=[[fromString substringFromIndex:[fromString rangeOfString:@":"].location+1] intValue];
                if([fromString intValue]==[toString intValue] && fromMinutes<59){
                    if(fromMinutes<45){
                        [theSelectedRide setObject:[dateFormat stringFromDate:[fromTime.date dateByAddingTimeInterval:15*60]] forKey:@"ArriveEnd"];
                    }else{
                        [theSelectedRide setObject:[dateFormat stringFromDate:[fromTime.date dateByAddingTimeInterval:(59-fromMinutes)*60]] forKey:@"ArriveEnd"];
                    }
                }else{
                    [theSelectedRide setObject:[dateFormat stringFromDate:[toTime.date dateByAddingTimeInterval:-30*60]] forKey:@"ArriveStart"];
                }
                
                
                
            }
        }else if([toTime.date timeIntervalSinceDate:fromTime.date]+timeBump>12*60*60){
         //   NSLog(@"resetting 2");
            if([sender isEqual:fromTime]){
                [theSelectedRide setObject:[dateFormat stringFromDate:[fromTime.date dateByAddingTimeInterval:12*60*60]] forKey:@"ArriveEnd"];
            }else{
                [theSelectedRide setObject:[dateFormat stringFromDate:[toTime.date dateByAddingTimeInterval:-12*60*60]] forKey:@"ArriveStart"];
            }
        }
    }else{
      //  NSLog(@"122");
        [theSelectedRide setObject:fromString forKey:@"LeaveStart"];
        [theSelectedRide setObject:toString forKey:@"LeaveEnd"];
        if([toTime.date timeIntervalSinceDate:fromTime.date]+timeBump<=0){
            if([sender isEqual:fromTime]){
                [theSelectedRide setObject:[dateFormat stringFromDate:[fromTime.date dateByAddingTimeInterval:30*60]] forKey:@"LeaveEnd"];
            }else{
                [theSelectedRide setObject:[dateFormat stringFromDate:[toTime.date dateByAddingTimeInterval:-30*60]] forKey:@"LeaveStart"];
            }
        }else if([toTime.date timeIntervalSinceDate:fromTime.date]+timeBump>12*60*60){
            if([sender isEqual:fromTime]){
                [theSelectedRide setObject:[dateFormat stringFromDate:[fromTime.date dateByAddingTimeInterval:12*60*60]] forKey:@"LeaveEnd"];
            }else{
                [theSelectedRide setObject:[dateFormat stringFromDate:[toTime.date dateByAddingTimeInterval:-12*60*60]] forKey:@"LeaveStart"];
            }
        }
    }
    
    
    [self reDrawTheScreen];
    
}


-(IBAction)showMap:(id)sender{
 //   NSLog(@"showmapn   %@",[sender titleForState:UIControlStateNormal] );
//    showHome.hidden=NO;
//    showWork.hidden=NO;
    mapIt.hidden=NO;
    fromTime.hidden=YES;
    toTime.hidden=YES;
    timeBetween.hidden=YES;
    cancelReturn.hidden=YES;
  //  tapToSet.hidden=YES;
    NSString *homeOrWork;
    
    double longitudeValue=-74.66;  //default to princeton
    double latitudeValue=40.35;    //default to princeton
    if([sender isEqual:showHome]){
    //    NSLog(@"show =home");
        
        if([theSelectedRide objectForKey:@"GeoA"]){
            longitudeValue=[[theSelectedRide objectForKey:@"GeoA"] doubleValue];
            [mapIt selectAnnotation:myHome animated:YES];
        }
        if([theSelectedRide objectForKey:@"GeoAlat"])
            latitudeValue=[[theSelectedRide objectForKey:@"GeoAlat"] doubleValue];
    }else if([sender isEqual:showWork]){
    //    NSLog(@"show work");
        homeOrWork=@"GeoB";
        if([theSelectedRide objectForKey:@"GeoB"]){
            longitudeValue=[[theSelectedRide objectForKey:homeOrWork] doubleValue];
            [mapIt selectAnnotation:myWork animated:YES];
        }
        if([theSelectedRide objectForKey:@"GeoBlat"]){
            latitudeValue=[[theSelectedRide objectForKey:@"GeoBlat"] doubleValue];
        }else{  // reset the scale because it is showing "Show princeton"
            
            
            CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(40.35, -74.66);
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coord, 1000, 1000);
            [mapIt setRegion:region];
            
            
        //    [mapIt setRegion:<#(MKCoordinateRegion)#>
        //    mapIt.region.span.latitudeDelta=.009006;
        }
    }
    if(sender){
        
   //     NSLog(@"the sender is %@    %f   %f",sender,mapIt.region.span.latitudeDelta,mapIt.region.span.longitudeDelta);
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latitudeValue,longitudeValue);
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coord,mapIt.region.span.latitudeDelta*1000/.009006, mapIt.region.span.longitudeDelta*1000/.014);
        
        [mapIt setRegion:region animated:YES];
        
    }
    
//    if nil then leave it where it is.
    
}


-(IBAction)resetLocation:(id)sender{
    
    BOOL setAToCancel=[[sender titleForState:UIControlStateNormal] isEqualToString:@"Reset 'Home'"] ||
                [[sender titleForState:UIControlStateNormal] isEqualToString:@"Set 'Home'"];
    BOOL setBToCancel=[[sender titleForState:UIControlStateNormal] isEqualToString:@"Reset 'Work'"] ||
                [[sender titleForState:UIControlStateNormal] isEqualToString:@"Set 'Work'"];
    BOOL goMatchRide=[[sender titleForState:UIControlStateNormal] isEqualToString:@"Match Ride"];
    
    if(!goMatchRide){
        [self showMap:nil];
        [self reDrawTheScreen];  // sets both to "Reset" or "set" or "show map"
        tapToSet.hidden=NO;
    }
    
    if(setAToCancel){
        tapToSet.text=@"Tap map to set 'Home' location";
        [sender setTitle:@"Cancel" forState:UIControlStateNormal];
        [resetA setTitleColor:[UIColor colorWithRed:0.0 green:122/255. blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    }else if(setBToCancel){
        tapToSet.text=@"Tap map to set 'Work' location";
        [sender setTitle:@"Cancel" forState:UIControlStateNormal];
        [resetB setTitleColor:[UIColor colorWithRed:0.0 green:122/255. blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        [arriveTimes setTitleColor:[UIColor colorWithRed:0.0 green:122/255. blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        [leaveTimes setTitleColor:[UIColor colorWithRed:0.0 green:122/255. blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    }else if(goMatchRide){ //cancel
        self.tabBarController.selectedIndex=2;
    }else{ //cancel
        tapToSet.hidden=YES;
    }
}

-(IBAction)infoButtonTapped:(id)sender{
    ChoicesViewController *choices = [[ChoicesViewController alloc] initWithNibName:@"ChoicesViewController" bundle:nil];
    [choices selectionIs:9];
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:choices];
    navigationController.modalPresentationStyle=UIModalPresentationFormSheet;
    navigationController.navigationBar.tintColor=[UIColor colorWithRed:.9 green:.0 blue:0 alpha:1.0];
    
    [self presentViewController:navigationController animated:YES completion:nil];
    
}

-(void)reDrawTheScreen{
    
  //  NSLog(@"the selectded ride   \n%@",theSelectedRide);
  //  NSLog(@"redraw with geoa %@   geoalat  %@",[theSelectedRide objectForKey:@"GeoA"],[theSelectedRide objectForKey:@"GeoAlat"]);
    resetB.hidden=NO;
    if ([theSelectedRide objectForKey:@"GeoB"]) {
        [resetB setTitle:@"Reset 'Work'" forState:UIControlStateNormal];
        [showWork setTitle:@"Show 'Work'" forState:UIControlStateNormal];
        showWork.hidden=mapIt.hidden;
        
        if(mapIt.hidden){
            if ([theSelectedRide objectForKey:@"GeoA"]){
              //  [resetB setTitle:@"" forState:UIControlStateNormal];
                
                
                if([theSelectedRide objectForKey:@"ArriveStart"] &&
                   [theSelectedRide objectForKey:@"LeaveStart"]){
                    resetB.hidden=NO;
                    [resetB setTitle:@"Match Ride" forState:UIControlStateNormal];
                }else{
                    resetB.hidden=YES;
                }
            }else{
                [resetB setTitle:@"Show map" forState:UIControlStateNormal];
            }
        }
    }else{
     //   [mapIt removeAnnotation:myWork];
        [resetB setTitle:@"Set 'Work'" forState:UIControlStateNormal];
        [showWork setTitle:@"Show Princeton" forState:UIControlStateNormal];
        showWork.hidden=mapIt.hidden;
    }
    if ([theSelectedRide objectForKey:@"GeoA"]) {
        [resetA setTitle:@"Reset 'Home'" forState:UIControlStateNormal];
        [showHome setTitle:@"Show 'Home'" forState:UIControlStateNormal];
        showHome.hidden=mapIt.hidden;
        if(mapIt.hidden)
            [resetA setTitle:@"Show map" forState:UIControlStateNormal];
        
    }else{
        [resetA setTitle:@"Set 'Home'" forState:UIControlStateNormal];
        showHome.hidden=YES;
    }
   
    
    tapToSet.hidden=YES;
    // set the times here
    
    
    deleteEntry.hidden=![theSelectedRide objectForKey:@"GeoA"]&& ![theSelectedRide objectForKey:@"GeoB"] &&
    ![theSelectedRide objectForKey:@"LeaveStart"] && ![theSelectedRide objectForKey:@"ArriveStart"];
    
    
    
    if([theSelectedRide objectForKey:@"ArriveStart"]){
    //    NSLog(@"13");
        [arriveTimes setTitle:
         [NSString stringWithFormat:@"%@ - %@",[theSelectedRide objectForKey:@"ArriveStart"],[theSelectedRide objectForKey:@"ArriveEnd"]]
                     forState:UIControlStateNormal];
        if([timeBetween.text isEqualToString:@"Leaving from 'Home'.\nArrive at 'Work' between the times:"]){
                [fromTime setDate:[dateFormat dateFromString:[theSelectedRide objectForKey:@"ArriveStart"]]];
                [toTime setDate:[dateFormat dateFromString:[theSelectedRide objectForKey:@"ArriveEnd"]]];
        }
    }else{
        [arriveTimes setTitle:@"  Set times" forState:UIControlStateNormal];
    }
    
    if([theSelectedRide objectForKey:@"LeaveStart"]){
        [leaveTimes setTitle:
         [NSString stringWithFormat:@"%@ - %@",[theSelectedRide objectForKey:@"LeaveStart"],[theSelectedRide objectForKey:@"LeaveEnd"]]
                    forState:UIControlStateNormal];
        if([timeBetween.text isEqualToString:@"Returning to 'Home'.\nLeave 'Work' between the times:"]){
                [fromTime setDate:[dateFormat dateFromString:[theSelectedRide objectForKey:@"LeaveStart"]]];
                [toTime setDate:[dateFormat dateFromString:[theSelectedRide objectForKey:@"LeaveEnd"]]];
        }
    }else{
        [leaveTimes setTitle:@"Set times" forState:UIControlStateNormal];
    }
    
    
    if(![theSelectedRide objectForKey:@"MyCarOrYours"]){
        [theSelectedRide setObject:[NSNumber numberWithLong:2] forKey:@"MyCarOrYours"];
        [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"UpdateInformation"];
    }
    [myCarOrYoursControl setSelectedSegmentIndex:[[theSelectedRide objectForKey:@"MyCarOrYours"] intValue]];

    
    
    //  move to location A ????   not always...a specific ride does not have a specific map location and you might want to compare the same location from ride to ride
    
    int daysOfTheWeek=31;
    if([theSelectedRide objectForKey:@"DaysOfTheWeek"]){
        daysOfTheWeek=[[theSelectedRide objectForKey:@"DaysOfTheWeek"] intValue];
    }else{
        [theSelectedRide setObject:[NSNumber numberWithLong:daysOfTheWeek] forKey:@"DaysOfTheWeek"];
        [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"UpdateInformation"];
    }
    UIColor *upperCaseColor=[UIColor colorWithRed:0 green:122/255. blue:1.0 alpha:1];
    UIColor *lowerCaseColor=[UIColor colorWithRed:0 green:122/255. blue:1.0 alpha:.5];
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
 //   [self saveDefaults];
    
    
    
    // set the colors:  (GeoA is already done fine)
    
    [resetB setTitleColor:[UIColor colorWithRed:0.0 green:122/255. blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    if([theSelectedRide objectForKey:@"GeoA"] && ![theSelectedRide objectForKey:@"GeoB"])
        [resetB setTitleColor:[UIColor colorWithRed:1.0 green:0. blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    
    if([[resetB titleForState:UIControlStateNormal] isEqualToString:@"Match Ride"])
        [resetB setTitleColor:[UIColor colorWithRed:1.0 green:0. blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    
    [resetA setTitleColor:[UIColor colorWithRed:0.0 green:122/255. blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    if(![theSelectedRide objectForKey:@"GeoA"] || resetB.hidden)
        [resetA setTitleColor:[UIColor colorWithRed:1.0 green:0. blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    
     [arriveTimes setTitleColor:[UIColor colorWithRed:0.0 green:122/255. blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    if([theSelectedRide objectForKey:@"GeoA"] && ![theSelectedRide objectForKey:@"ArriveStart"])
        [arriveTimes setTitleColor:[UIColor colorWithRed:1.0 green:0. blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    
    [leaveTimes setTitleColor:[UIColor colorWithRed:0.0 green:122/255. blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    if([theSelectedRide objectForKey:@"GeoA"] && ![theSelectedRide objectForKey:@"LeaveStart"])
        [leaveTimes setTitleColor:[UIColor colorWithRed:1.0 green:0. blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    matchRide.hidden=YES;
    if([theSelectedRide objectForKey:@"GeoA"] && [theSelectedRide objectForKey:@"LeaveStart"] && [theSelectedRide objectForKey:@"ArriveStart"] && [theSelectedRide objectForKey:@"GeoB"] && !mapIt.hidden)matchRide.hidden=NO;
    
    
    
}

-(IBAction)matchRides:(id)sender{
    
    self.tabBarController.selectedIndex=2;
    
}

-(IBAction)deleteThisEntry:(id)sender{
    [theSelectedRide removeAllObjects];
    timeBetween.text=@"cancelled";
    [mapIt removeAnnotation:myHome];
    [mapIt removeAnnotation:myWork];
    [self showMap:nil];
    [self reDrawTheScreen];
}


-(IBAction)cancelATrip:(id)sender{
    if([[sender titleForState:UIControlStateNormal] isEqualToString:@"Cancel leaving from 'Home'"]){
        [theSelectedRide removeObjectForKey:@"ArriveStart"];
        [theSelectedRide removeObjectForKey:@"ArriveEnd"];
    }else{
        [theSelectedRide removeObjectForKey:@"LeaveStart"];
        [theSelectedRide removeObjectForKey:@"LeaveEnd"];
    }
    timeBetween.text=@"cancelled";
    [self showMap:nil];
    [self reDrawTheScreen];
}


-(IBAction)myCarChanged:(id)sender{
    [theSelectedRide setObject:[NSNumber numberWithLong:myCarOrYoursControl.selectedSegmentIndex] forKey:@"MyCarOrYours"];
    [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"UpdateInformation"];
//    [self saveDefaults];
}

-(IBAction)changeSelectedRide:(UISegmentedControl *)sender{
    [parameters setObject:[NSNumber numberWithLong:rideSelector.selectedSegmentIndex] forKey:@"RideSelected"];
  
 //   NSLog(@"Ride changed");
    NSString *oldGeoA=[theSelectedRide objectForKey:@"GeoA"];
    NSString *oldGeoB=[theSelectedRide objectForKey:@"GeoB"];
    
 //   NSLog(@"the oldGeos are  %@   %@",oldGeoA,oldGeoB);
    
    
 //   rideSelector.selectedSegmentIndex=[[parameters objectForKey:@"RideSelected"] intValue];
    
    theSelectedRide=[theRides objectAtIndex:[rideSelector selectedSegmentIndex]];
    
 
    
    if((![theSelectedRide objectForKey:@"LeaveStart"]
       && [timeBetween.text isEqualToString:@"Returning to 'Home'.\nLeave 'Work' between the times:"]) ||
       (![theSelectedRide objectForKey:@"ArriveStart"]
        && [timeBetween.text isEqualToString:@"Leaving from 'Home'.\nArrive at 'Work' between the times:"]) ){
           
           
           //   show home or work?  this is called with nil from viewWillAppear so if nil don't change map
           //  here a time is not appropriate.
           //     since can always go to work or home, leave this where it was.
           
           
      //     NSLog(@"change ride selected and doing map");
           [self showMap:nil];
           
           timeBetween.text=@"cancelled";
           
           
       
       }
    
    
    if ([theSelectedRide objectForKey:@"GeoB"]) {
        myWork.coordinate=CLLocationCoordinate2DMake([[theSelectedRide objectForKey:@"GeoBlat"] doubleValue], [[theSelectedRide objectForKey:@"GeoB"] doubleValue]);
        if(!oldGeoB)[mapIt addAnnotation:myWork];
    }else if(oldGeoB){
        [mapIt removeAnnotation:myWork];
    }
    
    if ([theSelectedRide objectForKey:@"GeoA"]) {
        myHome.coordinate=CLLocationCoordinate2DMake([[theSelectedRide objectForKey:@"GeoAlat"] doubleValue], [[theSelectedRide objectForKey:@"GeoA"] doubleValue]);
        if(!oldGeoA)[mapIt addAnnotation:myHome];
    }else if(oldGeoA){
        [mapIt removeAnnotation:myHome];
    }
    
    
    [self reDrawTheScreen];
}

-(void)delayedViewDidLoad{
    
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
 //   NSLog(@"viewdidload second");
    mapIt.delegate=self;
    myHome=[[MKPointAnnotation alloc] init];
    myWork=[[MKPointAnnotation alloc] init];
    myHome.title=@"Home";
    myWork.title=@"Work";
    
    float shift=([[UIScreen mainScreen] bounds].size.height-568)/2;
    if (shift<0)shift=0;
    containingView.frame=CGRectMake(([[UIScreen mainScreen] bounds].size.width-320)/2,shift, 320, 568);
    
    
    dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"h:mm a"];
    
    [fromTime setDatePickerMode:UIDatePickerModeTime];
    [toTime setDatePickerMode:UIDatePickerModeTime];
    [fromTime addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
    [toTime addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
    
    
    
    [fromTime setBackgroundColor:[UIColor colorWithRed:.97 green:.97 blue:.97 alpha:1.0]];
    [toTime setBackgroundColor:[UIColor colorWithRed:.97 green:.97 blue:.97 alpha:1.0]];
    
    
    
                        
    // Do any additional setup after loading the view, typically from a nib.
    
    UITapGestureRecognizer* tapRec = [[UITapGestureRecognizer alloc]
                                      initWithTarget:self action:@selector(didTapMap:)];
    [mapIt addGestureRecognizer:tapRec];
    
  //  NSLog(@"did we get parameters? ");
    theRides=[parameters objectForKey:@"TheRides"];
 //   NSLog(@"did we get parameters?    %@",theRides);
    
    
    
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(40.35, -74.66);
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coord, 1000, 1000);
    [mapIt setRegion:region];
    

 //   [self performSelector:@selector(delayedViewDidLoad) withObject:nil afterDelay:8.1];
}

-(void) delayedViewWillAppear{
    
}

-(void)viewWillAppear:(BOOL)animated{
    
//    NSLog(@"viewwillappear second");
    [super viewWillAppear:animated];
    
    
    rideSelector.selectedSegmentIndex=[[parameters objectForKey:@"RideSelected"] intValue];
    [self changeSelectedRide:nil];  // sets theSelectedRide and resets map if needed then redraws the screen
    if([[parameters objectForKey:@"Set 'Home' location"] isEqualToString:@"yes"]){  // called from Match
        [self resetLocation:resetA];
        [parameters setObject:@"no" forKey:@"Set 'Home' location"];
    }
    
//    [self performSelector:@selector(delayedViewWillAppear) withObject:nil afterDelay:9.1];
    
}

- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>) annotation{
    
    MKAnnotationView *pinView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"pinView"];
    
 //   NSLog(@"doing it again is there a pinview?");
    
    if (!pinView)
        pinView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pinView"];
        
    
        if([annotation.title isEqualToString:@"Home"])
            pinView.image=[UIImage imageNamed:@"53-house white on black"];
            
            
        ////    [[UIImage imageNamed:@"53-house blue.png"] drawAtPoint:CGPointMake(0,10)];//30)];
    if([annotation.title isEqualToString:@"Work"])
        pinView.image=[UIImage imageNamed:@"177-building black on white"];
        
            
    pinView.centerOffset=CGPointMake(-2, -5);

        
        
        pinView.canShowCallout = YES;
        
   //     NSLog(@"annotation --- %@   %@",annotation.title,annotation);

    
    return pinView;
}



-(void)didTapMap:(UITapGestureRecognizer *)tapGesture{
    
    if(!mapIt.hidden && !tapToSet.hidden){
        
        CGPoint tapPoint=[tapGesture locationInView:mapIt];
        CLLocationCoordinate2D coord=[mapIt convertPoint:tapPoint toCoordinateFromView:mapIt];
   //     NSLog( @"the tapped spot is %f    %f",coord.longitude,coord.latitude);
        
        if ([tapToSet.text isEqualToString: @"Tap map to set 'Home' location"]){
            myHome.coordinate=coord;
            if(![theSelectedRide objectForKey:@"GeoA"]) [mapIt addAnnotation:myHome];
                
            
            
            showHome.hidden=NO;
            [theSelectedRide setObject:[NSNumber numberWithDouble:coord.longitude]forKey:@"GeoA"];
            [theSelectedRide setObject:[NSNumber numberWithDouble:coord.latitude]forKey:@"GeoAlat"];
            [theSelectedRide setObject:[NSDate dateWithTimeIntervalSinceNow:-1000]forKey:@"TimeLastDownloaded"];
        }else{
            myWork.coordinate=coord;
            myWork.title=@"Work";
            if(![theSelectedRide objectForKey:@"GeoB"]) [mapIt addAnnotation:myWork];
            [theSelectedRide setObject:[NSNumber numberWithDouble:coord.longitude]forKey:@"GeoB"];
            [theSelectedRide setObject:[NSNumber numberWithDouble:coord.latitude]forKey:@"GeoBlat"];
            showWork.hidden=NO;
     //       [self performSelector:@selector(delayAnnotationWork) withObject:nil afterDelay:0.5f];
        }
        tapToSet.hidden=YES;
        [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"UpdateInformation"];
        
        
        
                                            
                                            
        [self reDrawTheScreen];
    }

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
