//
//  GpsOnMapViewController.h
//  IIBProject
//
//  Created by Zhihao Cui on 27/01/2015.
//  Copyright (c) 2015 Zhihao Cui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreData/CoreData.h>
#import "DataStorage.h"

@interface GpsOnMapViewController : UIViewController <MKMapViewDelegate>

@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;

@property (strong, nonatomic) IBOutlet MKMapView *mapView;

@property NSPredicate* predicate;

@end
