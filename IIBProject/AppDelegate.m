//
//  AppDelegate.m
//  IIBProject
//
//  Created by Zhihao Cui on 14/01/2015.
//  Copyright (c) 2015 Zhihao Cui. All rights reserved.
//

#import "AppDelegate.h"
#import "MasterViewController.h"
#import "DataUsageTableViewController.h"
#import "UploadViewController.h"

// For Usage
#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <net/if_dl.h>


@interface AppDelegate ()

@property (nonatomic, retain) NSArray *dataCounters;
- (NSArray *)getDataCounters;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    MasterViewController *controller = (MasterViewController *)navigationController.topViewController;
    controller.managedObjectContext = self.managedObjectContext;
    
    
    // Start location services
    self.locationManager = [[CLLocationManager alloc] init];
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    // Only report to location manager if the user has traveled 1000 meters
    self.locationManager.distanceFilter = 200.0f;
    self.locationManager.delegate = self;
    self.locationManager.activityType = CLActivityTypeAutomotiveNavigation;
    
    // Start monitoring significant locations here as default, will switch to
    // update locations on enter foreground
    [self.locationManager startMonitoringSignificantLocationChanges];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"Went to Background.");
    // Need to stop regular updates first
    [self.locationManager stopUpdatingLocation];
    // Only monitor significant changes
    [self.locationManager startMonitoringSignificantLocationChanges];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self.locationManager stopMonitoringSignificantLocationChanges];
    [self.locationManager startUpdatingLocation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    BOOL isInBackground = NO;
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        isInBackground = YES;
    }
    
    // Handle location updates as normal, code omitted for brevity.
    // The omitted code should determine whether to reject the location update for being too
    // old, too close to the previous one, too inaccurate and so forth according to your own
    // application design.
    
//    if (isInBackground)
//    {
        if (!self.lastLocation) {
            self.lastLocation = newLocation;
        }
        
        if (newLocation.coordinate.latitude != self.lastLocation.coordinate.latitude &&
            newLocation.coordinate.longitude != self.lastLocation.coordinate.longitude) {
            self.lastLocation = newLocation;
        }
        
        CLLocation *currentLocation = newLocation;
        NSLog(@"New location: %f, %f",
              self.lastLocation.coordinate.latitude,
              self.lastLocation.coordinate.longitude);
        
        if (currentLocation != nil) {
            //        self.labelLongitude.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
            //        self.labelLatitude.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
        }
        
        self.dataCounters = self.getDataCounters;
        
        [self saveToCoreData];
        
        if (self.locationManager.location.speed > 10) self.locationManager.distanceFilter = 2000.0f;
        else if (self.locationManager.location.speed > 6) self.locationManager.distanceFilter = 1000.0f;
        else if (self.locationManager.location.speed > 3) self.locationManager.distanceFilter = 500.0f;
        else self.locationManager.distanceFilter = 200.0f;
//    }
//    else
//    {
//        if (!self.lastLocation) {
//            self.lastLocation = newLocation;
//        }
//        
//        if (newLocation.coordinate.latitude != self.lastLocation.coordinate.latitude &&
//            newLocation.coordinate.longitude != self.lastLocation.coordinate.longitude) {
//            self.lastLocation = newLocation;
//            NSLog(@"New location: %f, %f",
//                  self.lastLocation.coordinate.latitude,
//                  self.lastLocation.coordinate.longitude);
//            //        [self.locationMgr stopUpdatingLocation];
//        }
//        
//        CLLocation *currentLocation = newLocation;
//        NSLog(@"New location: %f, %f",
//              self.lastLocation.coordinate.latitude,
//              self.lastLocation.coordinate.longitude);
//        
//        if (currentLocation != nil) {
//            //        self.labelLongitude.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
//            //        self.labelLatitude.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
//        }
//        
//        self.dataCounters = self.getDataCounters;
//        
//        [self saveToCoreData];
//    }
}

- (void) saveToCoreData
{
    NSManagedObjectContext *context = [self managedObjectContext];
    DataStorage *dataUsageInfo = [NSEntityDescription
                                  insertNewObjectForEntityForName:@"DataStorage" inManagedObjectContext:context];
    dataUsageInfo.timeStamp =[NSDate date];
    dataUsageInfo.wifiSent = self.dataCounters[0];
    dataUsageInfo.wifiReceived =  self.dataCounters[1];
    dataUsageInfo.wwanSent = self.dataCounters[2];
    dataUsageInfo.wwanReceived = self.dataCounters[3];
    
    dataUsageInfo.gpsLatitude = [NSNumber numberWithDouble:self.lastLocation.coordinate.latitude];
    dataUsageInfo.gpsLongitude = [NSNumber numberWithDouble:self.lastLocation.coordinate.longitude];
    dataUsageInfo.estimateSpeed = [NSNumber numberWithDouble:self.lastLocation.speed];
    
    // Count all entities
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"DataStorage" inManagedObjectContext:self.managedObjectContext]];
    [fetchRequest setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    
    NSError *err;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&err];
    NSLog(@"Totoal entity Count = %lu",(unsigned long)count);
    if(count == NSNotFound) {
        //Handle error
    }
}
- (NSArray *)getDataCounters
{
    BOOL   success;
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor;
    const struct if_data *networkStatisc;
    
    int WiFiSent = 0;
    int WiFiReceived = 0;
    int WWANSent = 0;
    int WWANReceived = 0;
    
    NSString *name =[[NSString alloc]init];//autorelease];
    
    success = getifaddrs(&addrs) == 0;
    if (success)
    {
        cursor = addrs;
        while (cursor != NULL)
        {
            name=[NSString stringWithFormat:@"%s",cursor->ifa_name];
//            NSLog(@"ifa_name %s == %@\n", cursor->ifa_name,name);
            // names of interfaces: en0 is WiFi ,pdp_ip0 is WWAN
            
            if (cursor->ifa_addr->sa_family == AF_LINK)
            {
                if ([name hasPrefix:@"en"])
                {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    WiFiSent+=networkStatisc->ifi_obytes;
                    WiFiReceived+=networkStatisc->ifi_ibytes;
                    //                    NSLog(@"WiFiSent %d ==%d",WiFiSent,networkStatisc->ifi_obytes);
                    //                    NSLog(@"WiFiReceived %d ==%d",WiFiReceived,networkStatisc->ifi_ibytes);
                }
                
                if ([name hasPrefix:@"pdp_ip"])
                {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    WWANSent+=networkStatisc->ifi_obytes;
                    WWANReceived+=networkStatisc->ifi_ibytes;
                    //                    NSLog(@"WWANSent %d ==%d",WWANSent,networkStatisc->ifi_obytes);
                    //                    NSLog(@"WWANReceived %d ==%d",WWANReceived,networkStatisc->ifi_ibytes);
                }
            }
            
            cursor = cursor->ifa_next;
        }
        
        freeifaddrs(addrs);
    }
    
    return [NSArray arrayWithObjects:[NSNumber numberWithInt:WiFiSent], [NSNumber numberWithInt:WiFiReceived],[NSNumber numberWithInt:WWANSent],[NSNumber numberWithInt:WWANReceived], nil];
}



#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.zc246.IIBProject" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"IIBProject" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"IIBProject.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
