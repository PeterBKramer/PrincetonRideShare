//
//  messageViewer.m
//  PrincetonRideShare
//
//  Created by Peter B Kramer on 9/24/15.
//  Copyright (c) 2015 Peter B Kramer. All rights reserved.
//

#import "messageViewer.h"
#import "ChoicesViewController.h"



#import "messageViewer.h"

@interface messageViewer (){
    NSMutableArray *myMessages;
    NSMutableDictionary *parameters;
    int recordID;
    NSDateFormatter *dateFormat;
}


@end

@implementation messageViewer


-(void)viewWillAppear:(BOOL)animated{
    
    NSLog(@"viewwillappear messageViewer");
    [super viewWillAppear:animated];
    
}

-(void)getParameters:(NSMutableDictionary *)theParameters{
    parameters=theParameters;
    NSLog(@"get p");
}

-(void)hereIsTheRecordID:(NSNumber *)theRecordID{
    NSLog(@"here is the record id");
    recordID=[theRecordID intValue];
    
    
    
    //   self.view.backgroundColor=[UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1.0];
    UIBarButtonItem *dismissButton=[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(doneTapped)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    
    UIBarButtonItem *refreshButton=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(doneTapped)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    
    self.title=@"Tap entry to respond";

    
   // [NSString stringWithFormat:@"%i Messages",recordID];
    
    
}

-(void)doneTapped{
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}


-(IBAction)infoButton:(id)sender{
    [self showChoicesWith:7];
    
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





- (void)viewDidLoad {
    NSLog(@"viewDidLoad messageViewer");
    [super viewDidLoad];
    NSLog(@"post");
    
    
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
