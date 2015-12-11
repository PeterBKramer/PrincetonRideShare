//
//  CheckFor999.m
//  StocksOnClocks
//
//  Created by Peter B Kramer on 4/2/15.
//  Copyright (c) 2015 Peter B Kramer. All rights reserved.
//

#import "CheckFor999.h"


@interface CheckFor999 (){
    NSString *website;
    NSMutableDictionary *theParameters;
    NSMutableData *receivedData;
    NSMutableArray *theAlerts;
}

@end


@implementation CheckFor999


-(void)getParameters:(NSMutableDictionary *)parameters{
    
    theAlerts=[[NSMutableArray alloc] init];
    theParameters=parameters;
    website=@"https://sites.google.com/site/optionposition/princetonrideshare";
    NSURL *url= [[NSURL alloc] initWithString:website];
    NSURLRequest *req=[[NSURLRequest alloc] initWithURL:url];
    NSURLConnection *con=[[NSURLConnection alloc] initWithRequest:req delegate:self];
    if(con){
        receivedData = [[NSMutableData alloc] init];
    }
    
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    if(receivedData)[receivedData setLength:0];
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [receivedData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    receivedData=nil;
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    int messageNumberEntry=1;// so it goes through at least once
    int deviceCodeEntry;
    NSString *titleString;
    NSString *textString;
    NSString *receivedString=[[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    NSScanner *theScanner = [NSScanner scannerWithString:receivedString];
    
    while (messageNumberEntry!=0){   //   pbkpbk  26 35467825 pbkpbk title pbkpbk text pbkpbk
        [theScanner scanUpToString:@"pbkpbk" intoString:NULL];
        [theScanner scanString:@"pbkpbk" intoString:NULL];
        [theScanner scanInt:&messageNumberEntry];
        if(messageNumberEntry!=0){
            [theScanner scanInt:&deviceCodeEntry];
            [theScanner scanUpToString:@"pbkpbk" intoString:NULL];[theScanner scanString:@"pbkpbk" intoString:NULL];
            [theScanner scanUpToString:@"pbkpbk" intoString:&titleString];
            [theScanner scanString:@"pbkpbk" intoString:NULL];
            [theScanner scanUpToString:@"pbkpbk" intoString:&textString];
            [theScanner scanString:@"pbkpbk" intoString:NULL];
            
            if([titleString isEqualToString:@"Message Issue "]){
                [theParameters setObject:@"MessageIssue" forKey:@"MessageIssue"];
            }else if ([titleString isEqualToString:@"Message Issue Resolved "]){
                [theParameters removeObjectForKey:@"MessageIssue"];
            }
            
            NSNumber *theAlertNumber=[NSNumber numberWithInt:messageNumberEntry];
            
       //     NSLog(@"the alert numbers are.....%@    and does it contain %@",[theParameters objectForKey:@"DontDisplayList"],theAlertNumber);
      //      if([[theParameters objectForKey:@"DontDisplayList"] containsObject:theAlertNumber])NSLog(@"YES");
            if ( (deviceCodeEntry==0 || deviceCodeEntry==[[theParameters objectForKey:@"iCloudRecordID"] intValue]) &&  ![[theParameters objectForKey:@"DontDisplayList"] containsObject:theAlertNumber]) {  // all devices or for this device and not on the dont display list
                [theAlerts addObject:[NSDictionary dictionaryWithObjectsAndKeys:titleString,@"Title",textString,@"Text",theAlertNumber,@"AlertNumber",nil]];
            }
        }
    }
    receivedData=nil;
 //   NSLog(@"the alerts are   %@",theAlerts);
    
    if([theAlerts count]>0)[self performSelector:@selector(showAnAlert) withObject:nil afterDelay:4.0f];
}


-(void)showAnAlert{
    if([[UIApplication sharedApplication]keyWindow].rootViewController.presentedViewController){
        [self performSelector:@selector(showAnAlert) withObject:nil afterDelay:0.4f];
    }else{
        NSDictionary *thisAlert=[theAlerts objectAtIndex:0];
        
        UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:[thisAlert objectForKey:@"Title"]
             message:[thisAlert objectForKey:@"Text"]
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Don't remind me" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            [[theParameters objectForKey:@"DontDisplayList"] addObject:[thisAlert objectForKey:@"AlertNumber"]];
            
        //    NSLog(@"the alert numbers are now.....%@",[theParameters objectForKey:@"DontDisplayList"]);
            [theAlerts removeObjectAtIndex:0];
            if([theAlerts count]>0)[self showAnAlert];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Remind me" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
            [theAlerts removeObjectAtIndex:0];
            if([theAlerts count]>0)[self showAnAlert];
        }]];
        [[[UIApplication sharedApplication]keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
    }
}


@end
