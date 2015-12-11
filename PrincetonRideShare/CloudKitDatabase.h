//
//  CloudKitDatabase.h
//  PrincetonRideShare
//
//  Created by Peter B Kramer on 10/23/15.
//  Copyright (c) 2015 Peter B Kramer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudKit/CloudKit.h>
@interface CloudKitDatabase : NSObject


-(id)initWithParameters:(NSMutableDictionary *)theParameters;
-(void)setUpTheDatabases;
    
@end
