//
//  DataUsageTableViewController.m
//  SignalTest
//
//  Created by Zhihao Cui on 11/01/2015.
//  Copyright (c) 2015 Zhihao Cui. All rights reserved.
//

#import "DataUsageTableViewController.h"

// For Usage
#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <net/if_dl.h>


@interface DataUsageTableViewController ()

@property (nonatomic, retain) NSArray *dataCounters;

- (void) reloadDataCounters;
- (NSArray *)getDataCounters;

@end

@implementation DataUsageTableViewController

@synthesize dataCounters;
@synthesize managedObjectContext;
@synthesize locationMgr;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    locationMgr = [[CLLocationManager alloc]init];
    locationMgr.delegate = self;
    if ([self.locationMgr respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationMgr requestAlwaysAuthorization];
    }
    [self.locationMgr startUpdatingLocation];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
//        UIBarButtonItem *uploadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(uploadData)];
//        self.navigationItem.rightBarButtonItem = uploadButton;
//
    
    dataCounters = self.getDataCounters;
    
    // Initialize the refresh control.
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor purpleColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(reloadDataCounters)
                  forControlEvents:UIControlEventValueChanged];
    

    
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
    return dataCounters.count + 2; // 2 - GPS
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
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ bytes",dataCounters[indexPath.row]];
                break;
            case 1:
                cell.textLabel.text = @"WiFi Received";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ bytes",dataCounters[indexPath.row]];
                break;
            case 2:
                cell.textLabel.text = @"WWAN Sent";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ bytes",dataCounters[indexPath.row]];
                break;
            case 3:
                cell.textLabel.text = @"WWAN Received";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ bytes",dataCounters[indexPath.row]];
                break;
            case 5:
                cell.textLabel.text = @"Latitude";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%.8f", self.lastLocation.coordinate.latitude];
                break;
            case 4:
                cell.textLabel.text = @"Longitude";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%.8f", self.lastLocation.coordinate.longitude];
                break;
            default:
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

- (void) uploadData
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://129.169.245.174/~DavidCui/Direct/uploadDataUsage.php"]];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Y-m-d H:mm:s"];
    NSLog(@"%@",[formatter stringFromDate:[NSDate date]]);
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *allData = [[NSFetchRequest alloc] init];
    [allData setEntity:[NSEntityDescription entityForName:@"DataStorage" inManagedObjectContext:context]];
    [allData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * error = nil;
    NSArray * data = [context executeFetchRequest:allData error:&error];
    //error handling goes here
    int totalCounter = 0;
    

    
    for (DataStorage * dt in data) {
        NSString *post = [NSString stringWithFormat:@"deviceID=1&timeStamp=%@&wifiSent=%@&wifiReceived=%@&wwanSent=%@&wwanReceived=%@&",
                          [formatter stringFromDate:[NSDate date]],dt.wifiSent,dt.wifiReceived,dt.wwanSent,dt.wwanReceived];
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:postData];
        
        
        
        //[context deleteObject:dt];
        
        NSError *error;
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil     error:&error];
        if (returnData)
        {
            NSString *json=[[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
            NSLog(@"Resp string: %@",json);
        }
        else
        {
            NSLog(@"Error: %@", error);
        }
        
        
        totalCounter++;
        NSLog(@"Uploaded No.%d", totalCounter);
    }
    NSError *saveError = nil;
    [context save:&saveError];
    //more error handling here
    

    
    
    
    
    
}

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
    [self.locationMgr startUpdatingLocation];
    dataCounters = self.getDataCounters;
    [self reloadData];
}

- (void) saveToCoreData
{
    NSManagedObjectContext *context = [self managedObjectContext];
    DataStorage *dataUsageInfo = [NSEntityDescription
                                      insertNewObjectForEntityForName:@"DataStorage" inManagedObjectContext:context];
    dataUsageInfo.timeStamp =[NSDate date];
    dataUsageInfo.wifiSent = dataCounters[0];
    dataUsageInfo.wifiReceived =  dataCounters[1];
    dataUsageInfo.wwanSent = dataCounters[2];
    dataUsageInfo.wwanReceived = dataCounters[3];
    
    dataUsageInfo.gpsLatitude = [NSNumber numberWithDouble:self.lastLocation.coordinate.latitude];
    dataUsageInfo.gpsLongitude = [NSNumber numberWithDouble:self.lastLocation.coordinate.longitude];
    
    // Count all entities
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"DataStorage" inManagedObjectContext:managedObjectContext]];
    [fetchRequest setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    
    NSError *err;
    NSUInteger count = [managedObjectContext countForFetchRequest:fetchRequest error:&err];
    NSLog(@"Totoal entity Count = %lu",(unsigned long)count);
    if(count == NSNotFound) {
        //Handle error
    }

//    NSError *error;
//    if (![context save:&error]) {
//        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
//    }
//    
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    NSEntityDescription *entity = [NSEntityDescription
//                                   entityForName:@"DataStorage" inManagedObjectContext:context];
//    [fetchRequest setEntity:entity];
//    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
//    for (DataStorage *info in fetchedObjects) {
//        NSLog(@"timeStamp: %@", info.timeStamp);
//        NSLog(@"wifiSent: %@", info.wifiSent);
//        NSLog(@"wifiReceived: %@", info.wifiReceived);
//        NSLog(@"wwanSent: %@", info.wwanSent);
//        NSLog(@"wwanReceived: %@", info.wwanReceived);
//        NSLog(@"gpsLatitude: %@", info.gpsLatitude);
//        NSLog(@"gpsLongitude: %@", info.gpsLongitude);
//    }
}

- (void) clearCoreData
{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *allData = [[NSFetchRequest alloc] init];
    [allData setEntity:[NSEntityDescription entityForName:@"DataStorage" inManagedObjectContext:context]];
    [allData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * error = nil;
    NSArray * data = [context executeFetchRequest:allData error:&error];
    //error handling goes here
    for (NSManagedObject * dt in data) {
        [context deleteObject:dt];
    }
    NSError *saveError = nil;
    [context save:&saveError];
    //more error handling here
    NSLog(@"Cleared all data at %@", [NSDate date]);
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
//        [self.locationMgr stopUpdatingLocation];
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
    [self.locationMgr stopUpdatingLocation];
    
    
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

@end
