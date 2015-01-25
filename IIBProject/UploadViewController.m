//
//  UploadViewController.m
//  IIBProject
//
//  Created by Zhihao Cui on 15/01/2015.
//  Copyright (c) 2015 Zhihao Cui. All rights reserved.
//

#import "UploadViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "Reachability.h"

@interface UploadViewController ()

- (void)addToLog:(NSString *)input;

@property (strong, nonatomic) NSString *ipAddress;
@property (strong, nonatomic) NSString *defaultAddress;

@property (nonatomic, strong) CMMotionActivityManager *motionActivitiyManager;

@end

@implementation UploadViewController

@synthesize motionActivitiyManager = _motionActivitiyManager;

NSUUID * deviceUUID;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.logText.layer.borderWidth = 2.0f;
    self.logText.layer.borderColor = [[UIColor grayColor] CGColor];
    
    self.progressBar.hidden = 1;
    
    //default
    self.defaultAddress = @"192.168.165.100";
    self.ipAddress = self.defaultAddress;
    self.textField.text = self.ipAddress;
    
    deviceUUID = [[UIDevice currentDevice] identifierForVendor];
    
    
    if (_motionActivitiyManager == nil) {
        _motionActivitiyManager = [[CMMotionActivityManager alloc]init];
    }
    
    // TEST!!!
//    [self updateLastUpdateDate:[NSDate dateWithTimeIntervalSinceNow:-1*3600*24]];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)uploadButtonPressed:(id)sender {
    
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    if(status == NotReachable)
    {
        [self addToLog:[NSString stringWithFormat:@"Sorry, internet connection"]];
        return;
    }
    else if (status == ReachableViaWiFi)
    {
        //WiFi
    }
    else if (status == ReachableViaWWAN)
    {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Upload stopped"
                                                          message:@"Please connect to WiFi first!"
                                                         delegate:nil
                                                cancelButtonTitle:@"Back"
                                                otherButtonTitles:nil];
        [message show];

        return;
    }
    
    NSString* fullAddress = [NSString stringWithFormat:@"http://%@/~DavidCui/Direct/uploadDataUsage.php", self.ipAddress];
    
    IIBPostRequest *newRequest = [[IIBPostRequest alloc]initWithURLString:fullAddress];
    [newRequest setPostKey:@"UUID" withValue:deviceUUID.UUIDString];
    
    // Count all entities
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"DataStorage" inManagedObjectContext:self.managedObjectContext]];
    [fetchRequest setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    
    NSError *err;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&err];
    NSLog(@"Count = %lu",(unsigned long)count);
    if(count == NSNotFound) {
        //Handle error
    }
    
    if (count > 0) {
        self.progressBar.hidden = 0;
    }
    else {
        
        [self addToLog:[NSString stringWithFormat:@"Sorry, no data found in Core Data DB"]];
        return;
    }
    
    // Upload in background
    NSOperationQueue *progressQueue = [[NSOperationQueue alloc] init];
    [progressQueue addOperationWithBlock:^{
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Y-M-D H:mm:s"];
        //        NSLog(@"%@",[formatter stringFromDate:[NSDate date]]);
        
        NSManagedObjectContext *context = [self managedObjectContext];
        
        NSFetchRequest *allData = [[NSFetchRequest alloc] init];
        [allData setEntity:[NSEntityDescription entityForName:@"DataStorage" inManagedObjectContext:context]];
        [allData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
        
        NSError * error = nil;
        NSArray * data = [context executeFetchRequest:allData error:&error];
        //error handling goes here
        int currentCounter = 0;
        
        for (DataStorage * dt in data) {
            [newRequest setPostKey:@"timeStamp" withValue:[formatter stringFromDate:dt.timeStamp]];
            [newRequest setPostKey:@"wifiSent" withValue:[dt.wifiSent stringValue]];
            [newRequest setPostKey:@"wifiReceived" withValue:[dt.wifiReceived stringValue]];
            [newRequest setPostKey:@"wwanSent" withValue:[dt.wwanSent stringValue]];
            [newRequest setPostKey:@"wwanReceived" withValue:[dt.wwanReceived stringValue]];
            [newRequest setPostKey:@"gpsLatitude" withValue:[dt.gpsLatitude stringValue]];
            [newRequest setPostKey:@"gpsLongitude" withValue:[dt.gpsLongitude stringValue]];
            [newRequest setPostKey:@"estimateSpeed" withValue:[dt.estimateSpeed stringValue]];

            [newRequest prepareForPost];
            
            NSError *error;
            NSData *returnData = [NSURLConnection sendSynchronousRequest:newRequest returningResponse:nil     error:&error];
            if (returnData)
            {
                                NSString *json=[[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
                                NSLog(@"Resp string: %@",json);
                
                [context deleteObject:dt];

            }
            else
            {
                NSLog(@"Error: %@", error);
                break;
            }
            
            currentCounter++;
            NSLog(@"Uploaded No.%d", currentCounter);
            
            
            float progressValue = (float)currentCounter/count;
            
            if (progressValue == 1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.progressBar.hidden = 1;
                    [self addToLog:[NSString stringWithFormat:@"Uploaded %d entries", currentCounter]];
                });
                
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressBar setProgress:progressValue];
                });
            }
        }
        NSError *saveError = nil;
        [context save:&saveError];
        
    }];
    
    
    if ([CMMotionActivityManager isActivityAvailable]) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Further Upload"
                                                          message:@"Do you want to upload device activity?"
                                                         delegate:self
                                                cancelButtonTitle:@"Cancel"
                                                otherButtonTitles:@"Yes", nil];
        [message show];
        
    }
    
}

- (void)addToLog:(NSString *)input
{
    [[self.logText textStorage] appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@\n",[NSDate date],input]]];
}

- (IBAction)clearLogs:(id)sender {
    [self.logText setText:@""];
}

- (IBAction)startEditIP:(id)sender {
    [self.textField becomeFirstResponder];

}

- (IBAction)setIP:(id)sender {
    [self.textField resignFirstResponder];
    if ([self.textField.text length]>0) {
        self.ipAddress = self.textField.text;
    }
    // set to default value
    else{
        self.ipAddress = self.defaultAddress;
    }
    self.textField.text = self.ipAddress;
}

- (NSDate *)getLastUpdateTime
{
    // Get last uploaded time
    NSDate *lastUpdateTime;

    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *allData = [[NSFetchRequest alloc] init];
    [allData setEntity:[NSEntityDescription entityForName:@"MotionActivityRecord" inManagedObjectContext:context]];
    [allData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * error = nil;
    NSArray * data = [context executeFetchRequest:allData error:&error];
    
    
    NSDate *sevenDatesB4 = [NSDate dateWithTimeIntervalSinceNow:-7*24*3600+1];
    
    for (MotionActivityRecord * dt in data) {
        lastUpdateTime = dt.lastUpdateTime;
        break;
    }
    
    if (!(lastUpdateTime)) {
        lastUpdateTime = sevenDatesB4;
    }
    else lastUpdateTime = [lastUpdateTime laterDate:sevenDatesB4];
    
    return lastUpdateTime;
}

- (void)uploadMotionActivity
{
     NSDate *lastUpdateTime = [self getLastUpdateTime];
    
    
    UIActivityIndicatorView *activityView=[[UIActivityIndicatorView alloc]     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityView.center=self.view.center;
    [activityView startAnimating];
    [self.view addSubview:activityView];
    
    [_motionActivitiyManager queryActivityStartingFromDate:lastUpdateTime toDate:[NSDate date] toQueue:[NSOperationQueue mainQueue] withHandler:^(NSArray *activities, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                            message:[error description]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil, nil];
            [alert show];
            return ;
        }
        if (error != nil && error.code == CMErrorMotionActivityNotAuthorized) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addToLog:@"The app isn't authorized to use motion activity support."];
                [activityView stopAnimating];
            });
        }
        else{
            //            for (CMMotionActivity *activity in activities) {
            //                // Only need High confidence activity
            //                if (activity.confidence == CMMotionActivityConfidenceHigh) {
            //                    // Extract a function return all possible activity
            //                    if (activity.automotive) NSLog(@"Automotive: %d, Start date: %@", activity.automotive, activity.startDate);
            //                    if (activity.cycling) NSLog(@"Cycling: %d, Start date: %@", activity.cycling, activity.startDate);
            //                    if (activity.running) NSLog(@"Running: %d, Start date: %@", activity.running, activity.startDate);
            //                    if (activity.walking) NSLog(@"Walking: %d, Start date: %@", activity.walking, activity.startDate);
            //                    if (activity.stationary) NSLog(@"Stationary: %d, Start Date: %@", activity.stationary, activity.startDate);
            //                }
            //
            //            }
            
            NSString* fullAddress = [NSString stringWithFormat:@"http://%@/~DavidCui/Direct/uploadActivity.php", self.ipAddress];
            
            IIBPostRequest *newRequest = [[IIBPostRequest alloc]initWithURLString:fullAddress];
            [newRequest setPostKey:@"UUID" withValue:deviceUUID.UUIDString];
            
            // Upload in background
            NSOperationQueue *progressQueue = [[NSOperationQueue alloc] init];
            [progressQueue addOperationWithBlock:^{
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"Y-M-D H:mm:s"];
                //        NSLog(@"%@",[formatter stringFromDate:[NSDate date]]);
                
                NSManagedObjectContext *context = [self managedObjectContext];
                
                NSFetchRequest *allData = [[NSFetchRequest alloc] init];
                [allData setEntity:[NSEntityDescription entityForName:@"MotionActivityRecord" inManagedObjectContext:context]];
                [allData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
                
                int currentCounter = 0;
                
                BOOL uploadOK = 1;
                
                for (CMMotionActivity *activity in activities) {
                    if ((activity.confidence == CMMotionActivityConfidenceHigh)||(activity.confidence == CMMotionActivityConfidenceMedium)) {
                        // Extract a function return all possible activity
                        NSString *activityName;
                        if (activity.automotive) activityName = @"automotive";
                        else if (activity.cycling) activityName = @"cycling";
                        else if (activity.running) activityName = @"running";
                        else if (activity.walking) activityName = @"walking";
                        else if (activity.stationary) activityName = @"stationary";
                        else activityName = @"unknown";
                        
                        NSString *confidence;
                        
                        if (activity.confidence == CMMotionActivityConfidenceHigh) confidence = @"High";
                        else confidence = @"Medium";

                        [newRequest setPostKey:@"startTime" withValue:[formatter stringFromDate:activity.startDate]];
                        [newRequest setPostKey:@"activityName" withValue:activityName];
                        [newRequest setPostKey:@"confidenceLevel" withValue:confidence];
                        
                        [newRequest prepareForPost];
                        
                        NSError *error;
                        NSData *returnData = [NSURLConnection sendSynchronousRequest:newRequest returningResponse:nil     error:&error];
                        if (returnData)
                        {
                            //                            NSString *json=[[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
                            //                            NSLog(@"Resp string: %@",json);
                        }
                        else
                        {
                            NSLog(@"Error: %@", error);
                            uploadOK = 0;
                            break;
                        }
                        
                        currentCounter++;
                    }
                    
                    
                    
                }
                
                if (uploadOK) {
                    [self updateLastUpdateDate:[NSDate date]];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self addToLog:[NSString stringWithFormat:@"Uploaded %d high confidence motion activities.", currentCounter]];
                    [activityView stopAnimating];
                });
                
            }];
        }
    }];
}

- (void) updateLastUpdateDate:(NSDate *)lastUpdateDate
{
    // Get last uploaded time
    NSManagedObjectContext *context = [self managedObjectContext];
    
    // Count all entities
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"MotionActivityRecord" inManagedObjectContext:self.managedObjectContext]];
    [fetchRequest setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    
    NSError *err;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&err];
    NSLog(@"MotionActivityRecord Count = %lu",(unsigned long)count);
    if(count == NSNotFound) {
        //Handle error
    }
    
    if (count > 0) {
        NSFetchRequest *allData = [[NSFetchRequest alloc] init];
        [allData setEntity:[NSEntityDescription entityForName:@"MotionActivityRecord" inManagedObjectContext:context]];
        [allData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
        
        NSError * error = nil;
        NSArray * data = [context executeFetchRequest:allData error:&error];
        
        for (MotionActivityRecord * dt in data) {
            dt.lastUpdateTime = lastUpdateDate;
            break;
        }
    }
    else {
        NSManagedObjectContext *context = [self managedObjectContext];
        MotionActivityRecord *motionActivityRecord = [NSEntityDescription
                                      insertNewObjectForEntityForName:@"MotionActivityRecord" inManagedObjectContext:context];
        motionActivityRecord.lastUpdateTime = lastUpdateDate;
    }
    NSError *saveError = nil;
    [context save:&saveError];
   }

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqualToString:@"Yes"]) {
        [self uploadMotionActivity];
    }
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
