//
//  DataUsageTableViewController.m
//  SignalTest
//
//  Created by Zhihao Cui on 11/01/2015.
//  Copyright (c) 2015 Zhihao Cui. All rights reserved.
//

#import "DataUsageTableViewController.h"

#import "AppDelegate.h"

// For Data Usage
#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <net/if_dl.h>


@interface DataUsageTableViewController ()

@property (nonatomic, retain) NSArray *dataCounters;
@property (nonatomic, retain) NSMutableDictionary *motionData;


- (void) reloadDataCounters; 
- (NSArray *)getDataCounters;

@end

@implementation DataUsageTableViewController

CMMotionManager *motionManager;



- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Gps Controls
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    [self.locationManager startUpdatingLocation];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
//        UIBarButtonItem *uploadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(uploadData)];
//        self.navigationItem.rightBarButtonItem = uploadButton;
//
    
    self.dataCounters = self.getDataCounters;
    
    // Initialize the refresh control.
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor purpleColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(reloadDataCounters)
                  forControlEvents:UIControlEventValueChanged];
    
    // Motion sensors
    motionManager = [[CMMotionManager alloc] init];
    if (!motionManager.accelerometerAvailable) {
        NSLog(@"No accelerometer available! ");
    }
    else {
        motionManager.accelerometerUpdateInterval = 0.1;
        [self startDeviceUpdate];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.dataCounters.count + 2 + self.motionData.count; // 2 - GPS
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MyIdentifier = @"dataUsage";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2  reuseIdentifier:MyIdentifier];
    }
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"WiFi Sent";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ bytes",self.dataCounters[indexPath.row]];
            break;
        case 1:
            cell.textLabel.text = @"WiFi Received";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ bytes",self.dataCounters[indexPath.row]];
            break;
        case 2:
            cell.textLabel.text = @"WWAN Sent";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ bytes",self.dataCounters[indexPath.row]];
            break;
        case 3:
            cell.textLabel.text = @"WWAN Received";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ bytes",self.dataCounters[indexPath.row]];
            break;
        case 4:
            cell.textLabel.text = @"Longitude";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.8f", self.lastLocation.coordinate.longitude];
            break;
        case 5:
            cell.textLabel.text = @"Latitude";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.8f", self.lastLocation.coordinate.latitude];
            break;
        default:
            cell.textLabel.text = [[[self.motionData allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectAtIndex:indexPath.row-6];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [self.motionData objectForKey:cell.textLabel.text]];
            break;
    }
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)reloadData
{
    // Reload table data
    [self.tableView reloadData];
    
    // End the refreshing
    if (self.refreshControl) {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMM d, h:mm a"];
        NSString *title = [NSString stringWithFormat:@"Last update: %@", [formatter stringFromDate:[NSDate date]]];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
        self.refreshControl.attributedTitle = attributedTitle;
        
        [self.refreshControl endRefreshing];
    }
}

- (void) reloadDataCounters
{
    [self.locationManager startUpdatingLocation];
    self.dataCounters = self.getDataCounters;
    [self startDeviceUpdate];
    [self reloadData];
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
            //NSLog(@"ifa_name %s == %@\n", cursor->ifa_name,name);
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

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if (!self.lastLocation) {
        self.lastLocation = newLocation;
    }
    
    if (newLocation.coordinate.latitude != self.lastLocation.coordinate.latitude &&
        newLocation.coordinate.longitude != self.lastLocation.coordinate.longitude) {
        self.lastLocation = newLocation;
        NSLog(@"New location: %f, %f",
              self.lastLocation.coordinate.latitude,
              self.lastLocation.coordinate.longitude);
        [self.locationManager stopUpdatingLocation];
    }
    
    CLLocation *currentLocation = newLocation;
    NSLog(@"New location: %f, %f",
          self.lastLocation.coordinate.latitude,
          self.lastLocation.coordinate.longitude);
    
    if (currentLocation != nil) {
//        self.labelLongitude.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
//        self.labelLatitude.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
    }
    [self.tableView reloadData];
    [self.locationManager stopUpdatingLocation];
    
    
    [self saveToCoreData];
    
    
    // Reverse Geocoding
//    NSLog(@"Resolving the Address");
//    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
//        NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
//        if (error == nil && [placemarks count] > 0) {
//            placemark = [placemarks lastObject];
//            self.labelAddress.text = [NSString stringWithFormat:@"%@ %@\n%@ %@\n%@\n%@",
//                                      placemark.subThoroughfare, placemark.thoroughfare,
//                                      placemark.postalCode, placemark.locality,
//                                      placemark.administrativeArea,
//                                      placemark.country];
//            //[self.labelAddress sizeToFit];
//        } else {
//            NSLog(@"%@", error.debugDescription);
//        }
//    } ];
}

#pragma mark - Motion Sensors

- (void)startDeviceUpdate {
    [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
        
        [self.motionData setObject:[NSNumber numberWithDouble:motion.gravity.x] forKey:@"gravity.x"];
        [self.motionData setObject:[NSNumber numberWithDouble:motion.gravity.y] forKey:@"gravity.y"];
        [self.motionData setObject:[NSNumber numberWithDouble:motion.gravity.z] forKey:@"gravity.z"];
        
        [self.motionData setObject:[NSNumber numberWithDouble:motion.attitude.yaw] forKey:@"attitude.yaw"];
        [self.motionData setObject:[NSNumber numberWithDouble:motion.attitude.pitch] forKey:@"attitude.pitch"];
        [self.motionData setObject:[NSNumber numberWithDouble:motion.attitude.roll] forKey:@"attitude.roll"];
        
        [self stopMotionDetection];
    }];
    
    [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        self.motionData = [[NSMutableDictionary alloc]init];
        
        [self.motionData setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.x] forKey:@"acceleration.x"];
        [self.motionData setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.y] forKey:@"acceleration.y"];
        [self.motionData setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.z] forKey:@"acceleration.z"];
        
        [self stopAccelerometerDetection];
    }];
}

- (void) stopAccelerometerDetection
{
    [self.tableView reloadData];

    [motionManager stopAccelerometerUpdates];
}

- (void) stopMotionDetection
{
    [self.tableView reloadData];
    
    [motionManager stopDeviceMotionUpdates];
}

@end
