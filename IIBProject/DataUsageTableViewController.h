//
//  DataUsageTableViewController.h
//  SignalTest
//
//  Created by Zhihao Cui on 11/01/2015.
//  Copyright (c) 2015 Zhihao Cui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "DataStorage.h"

@protocol PassBackManagedObjectContextDelegate

- (void)recieveData:(NSManagedObjectContext *)theData;

@end

@interface DataUsageTableViewController : UITableViewController

@property (nonatomic, weak) id<PassBackManagedObjectContextDelegate> delegate;

@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;


@end
