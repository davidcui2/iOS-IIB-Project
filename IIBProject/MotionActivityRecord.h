//
//  MotionActivityRecord.h
//  IIBProject
//
//  Created by Zhihao Cui on 19/01/2015.
//  Copyright (c) 2015 Zhihao Cui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MotionActivityRecord : NSManagedObject

@property (nonatomic, retain) NSDate * lastUpdateTime;

@end
