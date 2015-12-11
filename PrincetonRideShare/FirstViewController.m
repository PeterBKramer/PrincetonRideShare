//
//  FirstViewController.m
//  PrincetonRideShare
//
//  Created by Peter B Kramer on 6/6/15.
//  Copyright (c) 2015 Peter B Kramer. All rights reserved.
//

#import "FirstViewController.h"
#import "ChoicesViewController.h"

@interface FirstViewController (){
    NSDictionary *parameters;
}

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    float shift=([[UIScreen mainScreen] bounds].size.height-480)/2;//568
    if (shift<0)shift=0;
    containingView.frame=CGRectMake(([[UIScreen mainScreen] bounds].size.width-320)/2,shift, 320, 568);
//    NSLog(@"......  %f",[[UIScreen mainScreen] bounds].size.height);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewWillAppearStuff)
                                                 name:@"UpdateIntroPage" object:nil];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self viewWillAppearStuff];
}

-(void)viewWillAppearStuff{
    if([[parameters objectForKey:@"iCloudRecordID"] intValue]==0){
        uniqueID.text=[NSString stringWithFormat:@"iCloud Drive ID\nnot assigned"];
    }else{
        uniqueID.text=[NSString stringWithFormat:@"iCloud Drive ID:\n%i",[[parameters objectForKey:@"iCloudRecordID"] intValue]];
    }
}

-(void)getParameters:(NSMutableDictionary *)theParameters{
    parameters=theParameters;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(IBAction)choiceRequest:(id)sender{
    ChoicesViewController *choices = [[ChoicesViewController alloc] initWithNibName:@"ChoicesViewController" bundle:nil];
    long showThis;
    if([sender isKindOfClass:[UIButton class]]){
        UIButton *aButton=sender;
        showThis=aButton.tag;
    }else{
        showThis=[sender intValue]; // might be 0.
    //    NSLog(@"the value is %li",showThis);
    }
    [choices selectionIs:showThis];
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:choices];
    navigationController.modalPresentationStyle=UIModalPresentationFormSheet;
    navigationController.navigationBar.tintColor=[UIColor colorWithRed:.9 green:.0 blue:0 alpha:1.0];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}


-(IBAction)selectorTapped:(UISegmentedControl *)sender{
    if(sender.selectedSegmentIndex==1){
            
        [self choiceRequest:[NSNumber numberWithInt:1]];
    
    }else if(sender.selectedSegmentIndex==2){
       // if([[sender titleForSegmentAtIndex:2] isEqualToString:@"Disclaimer"]){
            
            [self choiceRequest:[NSNumber numberWithInt:2]];
        
    }else if(sender.selectedSegmentIndex==0){
        
        [self choiceRequest:[NSNumber numberWithInt:3]];
     
        
    }else if(sender.selectedSegmentIndex==3){
        [self choiceRequest:[parameters objectForKey:@"iCloudRecordID"]];
    }else{
        [sender setTitle:@"About" forSegmentAtIndex:1];
        [sender setTitle:@"Disclaimer" forSegmentAtIndex:2];
        textDisplay.hidden=YES;
        
        
    }
    
    
}



@end
